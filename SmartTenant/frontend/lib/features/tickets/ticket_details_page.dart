import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/auth/auth_storage.dart';
import '../../core/ui/app_error.dart';
import '../ai/ai_service.dart';
import 'ticket_service.dart';

class TicketDetailsPage extends StatefulWidget {
  final String ticketId;

  const TicketDetailsPage({super.key, required this.ticketId});

  @override
  State<TicketDetailsPage> createState() => _TicketDetailsPageState();
}

class _TicketDetailsPageState extends State<TicketDetailsPage> {
  Map<String, dynamic>? ticket;
  List<dynamic> agents = [];

  bool loading = true;
  bool refreshing = false;
  bool sending = false;
  bool updatingStatus = false;
  bool assigning = false;
  bool deleting = false;
  bool suggestingReply = false;

  String error = '';
  String? role;
  String selectedSection = 'OVERVIEW';

  final messageCtrl = TextEditingController();

  static const primary = Color(0xFF6750A4);
  static const softBg = Color(0xFFF8F5FF);
  static const darkText = Color(0xFF1D1B20);

  bool get isTenant => role == 'TENANT';
  bool get isAssistant => role == 'ASSISTANT';
  bool get isAgent => role == 'AGENT';
  bool get isOwnerOrAdmin => role == 'ADMIN' || role == 'OWNER';
  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  bool get canManageTicket {
    return role == 'ADMIN' ||
        role == 'OWNER' ||
        role == 'AGENT' ||
        role == 'ASSISTANT';
  }

  bool get canAssignTicket {
    return role == 'ADMIN' || role == 'OWNER' || role == 'ASSISTANT';
  }

  bool get canDeleteTicket {
    return role == 'ADMIN' || role == 'OWNER';
  }

  bool get canLoadAgents {
    return role == 'ADMIN' || role == 'OWNER' || role == 'ASSISTANT';
  }

  List<String> get allowedStatuses {
    if (isOwnerOrAdmin) {
      return ['IN_PROGRESS', 'RESOLVED', 'CLOSED', 'OPEN'];
    }

    if (isAssistant) {
      return ['IN_PROGRESS', 'OPEN'];
    }

    if (isAgent) {
      return ['IN_PROGRESS', 'RESOLVED'];
    }

    return [];
  }

  bool get canUseAiReply {
    return role == 'ADMIN' ||
        role == 'OWNER' ||
        role == 'AGENT' ||
        role == 'ASSISTANT';
  }

  bool get canReply {
    return role == 'ADMIN' ||
        role == 'OWNER' ||
        role == 'AGENT' ||
        role == 'ASSISTANT' ||
        role == 'TENANT';
  }

  bool get hasDraftMessage => messageCtrl.text.trim().isNotEmpty;

  bool get busy {
    return sending ||
        updatingStatus ||
        assigning ||
        deleting ||
        suggestingReply ||
        refreshing;
  }

  @override
  void initState() {
    super.initState();
    messageCtrl.addListener(refresh);
    loadAll();
  }

  @override
  void dispose() {
    messageCtrl.removeListener(refresh);
    messageCtrl.dispose();
    super.dispose();
  }

  void refresh() {
    if (mounted) setState(() {});
  }

  Future<void> loadAll() async {
    setState(() {
      loading = true;
      error = '';
    });

    try {
      final userRole = await AuthStorage.getUserRole();

      if (!mounted) return;

      setState(() => role = userRole);

      final ticketData = await TicketService.getOne(widget.ticketId);

      List<dynamic> agentsData = [];

      // ADMIN, OWNER and ASSISTANT can load AGENT users for ticket dispatch.
      if (userRole == 'ADMIN' ||
          userRole == 'OWNER' ||
          userRole == 'ASSISTANT') {
        agentsData = await TicketService.getAgents();
      }

      if (!mounted) return;

      setState(() {
        ticket = ticketData;
        agents = agentsData;
        loading = false;
        error = '';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = AppError.clean(e);
        loading = false;
      });
    }
  }

  Future<void> loadTicket({bool showErrorSheet = false}) async {
    try {
      final data = await TicketService.getOne(widget.ticketId);

      if (!mounted) return;

      setState(() {
        ticket = data;
      });
    } catch (e) {
      if (!mounted) return;

      if (showErrorSheet) {
        await AppError.show(context, e, title: 'Could not refresh ticket');
      } else {
        showSnack(AppError.clean(e));
      }
    }
  }

  Future<void> refreshTicket() async {
    setState(() => refreshing = true);

    try {
      await loadTicket(showErrorSheet: true);
    } finally {
      if (mounted) {
        setState(() => refreshing = false);
      }
    }
  }

  Future<void> sendMessage() async {
    FocusScope.of(context).unfocus();

    if (!canReply) {
      await AppError.show(
        context,
        'You are not allowed to reply to this ticket.',
        title: 'Permission required',
      );
      return;
    }

    final body = messageCtrl.text.trim();

    if (body.isEmpty) {
      await AppError.show(
        context,
        'Write a message before sending.',
        title: 'Message required',
      );
      return;
    }

    setState(() => sending = true);

    try {
      await TicketService.addMessage(ticketId: widget.ticketId, body: body);

      messageCtrl.clear();

      if (!mounted) return;

      showSnack('Message sent successfully');
      await loadTicket();
    } catch (e) {
      if (!mounted) return;

      await AppError.show(context, e, title: 'Could not send message');
    } finally {
      if (mounted) {
        setState(() => sending = false);
      }
    }
  }

  Future<void> changeStatus(String status) async {
    if (!canManageTicket) {
      showMessage('You are not allowed to update ticket status');
      return;
    }

    if (!allowedStatuses.contains(status)) {
      showMessage('Your role cannot move this ticket to $status');
      return;
    }

    setState(() => updatingStatus = true);

    final currentStatus = ticketStatus();

    if (currentStatus == status) return;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SafeActionSheet(
        icon: statusIcon(status),
        color: statusColor(status),
        title: 'Update Ticket Status?',
        message:
            'Move this ticket from $currentStatus to $status. This may notify related users and update the activity timeline.',
        confirmText: 'Update Status',
      ),
    );

    if (confirmed != true) return;

    setState(() => updatingStatus = true);

    try {
      await TicketService.updateStatus(
        ticketId: widget.ticketId,
        status: status,
      );

      if (!mounted) return;

      showSnack('Ticket status updated');
      await loadTicket();
    } catch (e) {
      if (!mounted) return;

      await AppError.show(context, e, title: 'Could not update ticket status');
    } finally {
      if (mounted) {
        setState(() => updatingStatus = false);
      }
    }
  }

  Future<void> assignTo(String userId) async {
    if (!canAssignTicket) {
      showMessage('Only admins, owners and assistants can assign tickets');
      return;
    }

    setState(() => assigning = true);

    try {
      await TicketService.assign(ticketId: widget.ticketId, userId: userId);

      if (!mounted) return;

      showSnack('Ticket assigned successfully');
      await loadTicket();
    } catch (e) {
      if (!mounted) return;

      await AppError.show(context, e, title: 'Could not assign ticket');
    } finally {
      if (mounted) {
        setState(() => assigning = false);
      }
    }
  }

  Future<void> deleteTicket() async {
    if (!canDeleteTicket) {
      await AppError.show(
        context,
        'Only admins and owners can delete tickets.',
        title: 'Permission required',
      );
      return;
    }

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SafeActionSheet(
        icon: Icons.delete_outline,
        color: Colors.red,
        title: 'Delete Ticket?',
        message:
            'This will permanently delete the ticket and its conversation history. This action cannot be undone.',
        confirmText: 'Delete Ticket',
      ),
    );

    if (confirmed != true) return;

    setState(() => deleting = true);

    try {
      await TicketService.delete(widget.ticketId);

      if (!mounted) return;

      showSnack('Ticket deleted');
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      await AppError.show(context, e, title: 'Could not delete ticket');
    } finally {
      if (mounted) {
        setState(() => deleting = false);
      }
    }
  }

  Future<void> generateAiReply() async {
    if (!canUseAiReply) {
      await AppError.show(
        context,
        'AI replies are available for admins, owners, agents and assistants.',
        title: 'AI access restricted',
      );
      return;
    }

    final sourceMessage = aiSourceMessage();

    if (sourceMessage.trim().isEmpty) {
      await AppError.show(
        context,
        'No tenant message or ticket description was found to generate a reply.',
        title: 'No message context',
      );
      return;
    }

    setState(() => suggestingReply = true);

    try {
      final result = await AiService.suggestReply(
        message: sourceMessage,
        tone: 'professional',
      );

      if (!mounted) return;

      await showAiReplySheet(result);
    } catch (e) {
      if (!mounted) return;

      await AppError.show(context, e, title: 'Could not generate AI reply');
    } finally {
      if (mounted) {
        setState(() => suggestingReply = false);
      }
    }
  }

  String aiSourceMessage() {
    final ticketMessages = messages();

    for (final message in ticketMessages.reversed) {
      final senderRole = message['sender']?['role']?.toString();

      if (senderRole == 'TENANT') {
        final body = message['body']?.toString() ?? '';

        if (body.trim().isNotEmpty) return body;
      }
    }

    final description = ticketDescription();

    if (description.trim().isNotEmpty) return description;

    final title = ticketTitle();

    if (title.trim().isNotEmpty) return title;

    return messageCtrl.text.trim();
  }

  Future<void> showAiReplySheet(Map<String, dynamic> result) async {
    final suggestedReply = result['suggestedReply']?.toString() ?? '';
    final category = result['category']?.toString() ?? 'GENERAL';
    final urgency = result['urgency']?.toString() ?? 'NORMAL';

    final quickRepliesRaw = result['quickReplies'];
    final nextActionsRaw = result['nextActions'];

    final quickReplies = quickRepliesRaw is List ? quickRepliesRaw : [];
    final nextActions = nextActionsRaw is List ? nextActionsRaw : [];

    if (suggestedReply.trim().isEmpty) {
      await AppError.show(
        context,
        'AI did not return a usable reply.',
        title: 'No reply generated',
      );
      return;
    }

    final selectedReply = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AiReplySheet(
        suggestedReply: suggestedReply,
        category: category,
        urgency: urgency,
        quickReplies: quickReplies,
        nextActions: nextActions,
      ),
    );

    if (selectedReply != null && selectedReply.trim().isNotEmpty) {
      messageCtrl.text = selectedReply;
      messageCtrl.selection = TextSelection.fromPosition(
        TextPosition(offset: messageCtrl.text.length),
      );

      if (!mounted) return;

      showSnack('AI reply added to message box');
    }
  }

  Future<void> openTicketInsights() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TicketInsightsSheet(
        title: ticketTitle(),
        status: ticketStatus(),
        priority: ticketPriority(),
        healthScore: ticketHealthScore,
        healthLabel: ticketHealthLabel(),
        healthColor: ticketHealthColor(),
        progressPercent: progressPercent,
        messageCount: messageCount,
        tenantMessageCount: tenantMessageCount,
        staffMessageCount: staffMessageCount,
        assignedName: assignedName(),
        ageLabel: ticketAgeLabel(),
        propertyName: propertyName(),
        unitName: unitName(),
      ),
    );
  }

  void showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String userName(dynamic user) {
    if (user == null) return 'Unassigned';

    final firstName = user['firstName']?.toString() ?? '';
    final lastName = user['lastName']?.toString() ?? '';
    final email = user['email']?.toString() ?? '';

    final fullName = '$firstName $lastName'.trim();

    if (fullName.isNotEmpty) return fullName;
    if (email.isNotEmpty) return email;

    return 'User';
  }

  String creatorName() => userName(ticket?['createdBy']);

  String assignedName() => userName(ticket?['assignedTo']);

  String propertyName() {
    final property = ticket?['property'];

    if (property != null) {
      return property['title']?.toString() ??
          property['name']?.toString() ??
          property['address']?.toString() ??
          'Property';
    }

    return 'No property';
  }

  String unitName() {
    final unit = ticket?['unit'];

    if (unit != null) {
      return unit['title']?.toString() ?? unit['number']?.toString() ?? 'Unit';
    }

    return 'No unit';
  }

  String ticketTitle() {
    final value = ticket?['title']?.toString();

    if (value == null || value.trim().isEmpty) return 'Ticket';

    return value.trim();
  }

  String ticketDescription() {
    final value = ticket?['description']?.toString();

    if (value == null || value.trim().isEmpty) {
      return 'No description provided';
    }

    return value.trim();
  }

  String ticketStatus() {
    return ticket?['status']?.toString() ?? 'OPEN';
  }

  String ticketPriority() {
    return ticket?['priority']?.toString() ?? 'medium';
  }

  DateTime parseDate(dynamic value) {
    if (value == null) return DateTime.fromMillisecondsSinceEpoch(0);

    return DateTime.tryParse(value.toString()) ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  String formatDate(dynamic value) {
    if (value == null) return '—';

    final parsed = DateTime.tryParse(value.toString());

    if (parsed == null) return value.toString();

    return parsed.toLocal().toString().split('.')[0];
  }

  List<dynamic> messages() {
    final data = ticket?['messages'];

    if (data is List) return data;

    return [];
  }

  int get messageCount => messages().length;

  int get tenantMessageCount {
    return messages().where((message) {
      return message['sender']?['role']?.toString() == 'TENANT';
    }).length;
  }

  int get staffMessageCount {
    return messages().where((message) {
      final senderRole = message['sender']?['role']?.toString();

      return senderRole == 'ADMIN' ||
          senderRole == 'OWNER' ||
          senderRole == 'AGENT' ||
          senderRole == 'ASSISTANT';
    }).length;
  }

  int get progressPercent {
    switch (ticketStatus()) {
      case 'OPEN':
        return 20;
      case 'IN_PROGRESS':
        return 55;
      case 'RESOLVED':
        return 85;
      case 'CLOSED':
        return 100;
      default:
        return 0;
    }
  }

  int get ticketAgeDays {
    final createdAt = parseDate(ticket?['createdAt']);

    if (createdAt.millisecondsSinceEpoch == 0) return 0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final createdDay = DateTime(createdAt.year, createdAt.month, createdAt.day);

    return today.difference(createdDay).inDays.clamp(0, 999999);
  }

  String ticketAgeLabel() {
    final days = ticketAgeDays;

    if (days == 0) return 'Created today';
    if (days == 1) return '1 day old';

    return '$days days old';
  }

  int get ticketHealthScore {
    final status = ticketStatus();
    final priority = ticketPriority();

    if (status == 'CLOSED') return 100;
    if (status == 'RESOLVED') return 90;

    int score = 65;

    if (status == 'IN_PROGRESS') score += 10;
    if (ticket?['assignedTo'] != null || ticket?['assignedToId'] != null) {
      score += 10;
    }
    if (messageCount > 0) score += 10;

    if (priority == 'urgent') score -= 25;
    if (priority == 'high') score -= 15;
    if (ticketAgeDays >= 7) score -= 15;
    if (ticketAgeDays >= 14) score -= 15;

    return score.clamp(0, 100);
  }

  String ticketHealthLabel() {
    final status = ticketStatus();

    if (status == 'CLOSED') return 'Closed';
    if (status == 'RESOLVED') return 'Resolved';
    if (ticketPriority() == 'urgent') return 'Urgent';
    if (ticket?['assignedTo'] == null && ticket?['assignedToId'] == null) {
      return 'Unassigned';
    }
    if (ticketAgeDays >= 7) return 'Aging';

    return 'On track';
  }

  Color ticketHealthColor() {
    final label = ticketHealthLabel();

    switch (label) {
      case 'Closed':
        return Colors.grey;
      case 'Resolved':
      case 'On track':
        return Colors.green;
      case 'Urgent':
      case 'Aging':
        return Colors.red;
      case 'Unassigned':
        return Colors.orange;
      default:
        return primary;
    }
  }

  Color statusColor(String? status) {
    switch (status) {
      case 'OPEN':
        return Colors.red;
      case 'IN_PROGRESS':
        return Colors.orange;
      case 'RESOLVED':
        return Colors.green;
      case 'CLOSED':
        return Colors.grey;
      default:
        return Colors.blueGrey;
    }
  }

  IconData statusIcon(String? status) {
    switch (status) {
      case 'OPEN':
        return Icons.report_problem;
      case 'IN_PROGRESS':
        return Icons.sync;
      case 'RESOLVED':
        return Icons.check_circle;
      case 'CLOSED':
        return Icons.lock;
      default:
        return Icons.construction;
    }
  }

  String statusDescription(String? status) {
    switch (status) {
      case 'OPEN':
        return 'This request is new and needs attention.';
      case 'IN_PROGRESS':
        return 'The team is currently working on this request.';
      case 'RESOLVED':
        return 'The issue has been resolved and is waiting for closure.';
      case 'CLOSED':
        return 'This ticket has been closed and archived.';
      default:
        return 'Ticket status information is unavailable.';
    }
  }

  Color priorityColor(String? priority) {
    switch (priority) {
      case 'urgent':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.blue;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData priorityIcon(String? priority) {
    switch (priority) {
      case 'urgent':
        return Icons.priority_high;
      case 'high':
        return Icons.keyboard_double_arrow_up;
      case 'medium':
        return Icons.remove_circle_outline;
      case 'low':
        return Icons.keyboard_arrow_down;
      default:
        return Icons.flag;
    }
  }

  String priorityDescription(String? priority) {
    switch (priority) {
      case 'urgent':
        return 'Critical issue requiring immediate action.';
      case 'high':
        return 'Important issue that should be handled soon.';
      case 'medium':
        return 'Normal maintenance priority.';
      case 'low':
        return 'Minor issue with no immediate risk.';
      default:
        return 'Priority information is unavailable.';
    }
  }

  Widget dragHandle() {
    return Center(
      child: Container(
        width: 42,
        height: 5,
        decoration: BoxDecoration(
          color: Colors.grey.shade400,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  Widget infoRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 116,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value?.toString().isNotEmpty == true ? value.toString() : '—',
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget heroMetric({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget heroHeader() {
    final status = ticketStatus();
    final priority = ticketPriority();
    final color = statusColor(status);
    final healthColor = ticketHealthColor();

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4C1D95), Color(0xFF6750A4), Color(0xFF8B7DD8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.25),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 31,
                backgroundColor: Colors.white,
                child: Icon(statusIcon(status), color: color, size: 31),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isTenant
                          ? 'My Request'
                          : isAssistant
                          ? 'Support Ticket'
                          : 'Ticket Details',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 27,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ticketTitle(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: refreshing ? null : refreshTicket,
                icon: refreshing
                    ? const SizedBox(
                        width: 19,
                        height: 19,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.refresh, color: Colors.white),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(
                avatar: Icon(statusIcon(status), color: color, size: 18),
                label: Text(status),
                backgroundColor: Colors.white,
                labelStyle: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
                side: BorderSide.none,
              ),
              Chip(
                avatar: Icon(
                  priorityIcon(priority),
                  color: priorityColor(priority),
                  size: 18,
                ),
                label: Text(priority),
                backgroundColor: Colors.white,
                labelStyle: TextStyle(
                  color: priorityColor(priority),
                  fontWeight: FontWeight.bold,
                ),
                side: BorderSide.none,
              ),
              Chip(
                avatar: Icon(
                  Icons.health_and_safety,
                  color: healthColor,
                  size: 18,
                ),
                label: Text(ticketHealthLabel()),
                backgroundColor: Colors.white,
                labelStyle: TextStyle(
                  color: healthColor,
                  fontWeight: FontWeight.bold,
                ),
                side: BorderSide.none,
              ),
            ],
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: heroMetric(
                  title: 'Messages',
                  value: messageCount.toString(),
                  icon: Icons.chat,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: heroMetric(
                  title: 'Progress',
                  value: '$progressPercent%',
                  icon: Icons.auto_graph,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: heroMetric(
                  title: 'Health',
                  value: '$ticketHealthScore%',
                  icon: Icons.health_and_safety,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: heroMetric(
                  title: 'Age',
                  value: ticketAgeLabel(),
                  icon: Icons.schedule,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              Icon(statusIcon(status), color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  statusDescription(status),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progressPercent / 100,
              minHeight: 9,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget quickActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: openTicketInsights,
                    icon: const Icon(Icons.insights),
                    label: const Text('Insights'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: refreshing ? null : refreshTicket,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                  ),
                ),
              ],
            ),
            if (canUseAiReply) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: suggestingReply ? null : generateAiReply,
                  icon: suggestingReply
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome),
                  label: Text(
                    suggestingReply
                        ? 'Generating AI Reply...'
                        : 'Suggest Reply with AI',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget sectionSwitch() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            sectionChip('OVERVIEW', 'Overview', Icons.dashboard_customize),
            const SizedBox(width: 8),
            sectionChip('CHAT', 'Chat', Icons.chat),
            const SizedBox(width: 8),
            sectionChip('WORKFLOW', 'Workflow', Icons.timeline),
          ],
        ),
      ),
    );
  }

  Widget sectionChip(String value, String label, IconData icon) {
    final selected = selectedSection == value;

    return Expanded(
      child: ChoiceChip(
        selected: selected,
        label: Text(label),
        avatar: Icon(icon, size: 18, color: selected ? Colors.white : primary),
        selectedColor: primary,
        backgroundColor: primary.withOpacity(0.08),
        labelStyle: TextStyle(
          color: selected ? Colors.white : primary,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        side: BorderSide.none,
        onSelected: (_) => setState(() => selectedSection = value),
      ),
    );
  }

  Widget summaryCard() {
    final status = ticketStatus();
    final priority = ticketPriority();
    final color = statusColor(status);
    final pColor = priorityColor(priority);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: color.withOpacity(0.12),
                  child: Icon(statusIcon(status), color: color),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ticketTitle(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: darkText,
                          fontWeight: FontWeight.bold,
                          fontSize: 19,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${propertyName()} • ${unitName()}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Created by: ${creatorName()}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Chip(
                      label: Text(status),
                      backgroundColor: color.withOpacity(0.12),
                      labelStyle: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                      side: BorderSide.none,
                    ),
                    Chip(
                      avatar: Icon(
                        priorityIcon(priority),
                        size: 16,
                        color: pColor,
                      ),
                      label: Text(priority),
                      backgroundColor: pColor.withOpacity(0.12),
                      labelStyle: TextStyle(
                        color: pColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                      side: BorderSide.none,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: softBg,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  infoRow('Created by', creatorName()),
                  infoRow('Assigned', assignedName()),
                  infoRow('Property', propertyName()),
                  infoRow('Unit', unitName()),
                  infoRow('Created', formatDate(ticket?['createdAt'])),
                  infoRow('Updated', formatDate(ticket?['updatedAt'])),
                  infoRow('Description', ticketDescription()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget statusMeaningCard() {
    final status = ticketStatus();
    final priority = ticketPriority();
    final color = statusColor(status);
    final pColor = priorityColor(priority);

    return Column(
      children: [
        Card(
          color: color.withOpacity(0.07),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: color.withOpacity(0.12),
                  child: Icon(statusIcon(status), color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    statusDescription(status),
                    style: TextStyle(color: Colors.grey.shade800, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Card(
          color: pColor.withOpacity(0.07),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: pColor.withOpacity(0.12),
                  child: Icon(priorityIcon(priority), color: pColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    priorityDescription(priority),
                    style: TextStyle(color: Colors.grey.shade800, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget readOnlyNotice() {
    if (!isTenant && !isAssistant) return const SizedBox.shrink();

    final text = isAssistant
        ? 'Assistant access can view the ticket, reply to messages, use AI replies, assign tickets to agents, and move tickets between OPEN and IN_PROGRESS.'
        : 'You can follow updates and reply to messages. The management team controls assignment and workflow status.';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: primary.withOpacity(0.12),
              child: const Icon(Icons.info_outline, color: primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(color: Colors.grey.shade700, height: 1.35),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget assignmentCard() {
    if (!canAssignTicket) {
      return const SizedBox.shrink();
    }

    final assignedToId = ticket?['assignedToId']?.toString();

    String agentLabel(dynamic agent) {
      final firstName = agent['firstName']?.toString() ?? '';
      final lastName = agent['lastName']?.toString() ?? '';
      final email = agent['email']?.toString() ?? 'User';
      final agentRole = agent['role']?.toString() ?? '';

      final fullName = '$firstName $lastName'.trim();
      final name = fullName.isNotEmpty ? fullName : email;

      return agentRole.isEmpty ? name : '$name ($agentRole)';
    }

    final validValue =
        agents.any((agent) {
          return agent['id']?.toString() == assignedToId;
        })
        ? assignedToId
        : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: primary.withOpacity(0.12),
                  child: const Icon(Icons.assignment_ind, color: primary),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Assignment',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                if (assigning)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),

            const SizedBox(height: 14),

            if (agents.isEmpty)
              const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.info_outline),
                title: Text('No agents available'),
                subtitle: Text(
                  'Create an AGENT user in this organization first.',
                ),
              )
            else
              DropdownButtonFormField<String>(
                value: validValue,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Assigned Staff / Agent',
                  prefixIcon: Icon(Icons.person_search),
                ),
                items: agents.map((agent) {
                  return DropdownMenuItem<String>(
                    value: agent['id']?.toString(),
                    child: Text(
                      agentLabel(agent),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: assigning
                    ? null
                    : (value) {
                        if (value == null) return;
                        assignTo(value);
                      },
              ),
          ],
        ),
      ),
    );
  }

  String workflowTitle(String status) {
    switch (status) {
      case 'OPEN':
        return 'Reopen Ticket';
      case 'IN_PROGRESS':
        return 'Start Work';
      case 'RESOLVED':
        return 'Mark Resolved';
      case 'CLOSED':
        return 'Close Ticket';
      default:
        return status;
    }
  }

  String workflowSubtitle(String status) {
    switch (status) {
      case 'OPEN':
        return 'Send this ticket back to the support queue.';
      case 'IN_PROGRESS':
        return 'Confirm that work has started on this request.';
      case 'RESOLVED':
        return 'Mark the issue as completed by maintenance.';
      case 'CLOSED':
        return 'Finalize and lock this ticket workflow.';
      default:
        return 'Update ticket workflow status.';
    }
  }

  Color workflowColor(String status) {
    switch (status) {
      case 'OPEN':
        return Colors.red;
      case 'IN_PROGRESS':
        return Colors.orange;
      case 'RESOLVED':
        return Colors.green;
      case 'CLOSED':
        return Colors.grey;
      default:
        return primary;
    }
  }

  IconData workflowIcon(String status) {
    switch (status) {
      case 'OPEN':
        return Icons.refresh;
      case 'IN_PROGRESS':
        return Icons.play_arrow;
      case 'RESOLVED':
        return Icons.check_circle;
      case 'CLOSED':
        return Icons.lock;
      default:
        return Icons.sync;
    }
  }

  Widget workflowActionButton({
    required String label,
    required String status,
    required IconData icon,
    required Color color,
  }) {
    final currentStatus = ticket?['status']?.toString() ?? 'OPEN';
    final isCurrent = currentStatus == status;
    final isAllowed = allowedStatuses.contains(status);
    final disabled = updatingStatus || isCurrent || !isAllowed;

    final actionColor = workflowColor(status);

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: disabled ? 0.62 : 1,
      child: Material(
        color: disabled ? Colors.grey.withOpacity(0.08) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: disabled ? null : () => changeStatus(status),
          child: Container(
            width: 165,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isCurrent
                    ? actionColor.withOpacity(0.35)
                    : actionColor.withOpacity(0.16),
              ),
              boxShadow: disabled
                  ? []
                  : [
                      BoxShadow(
                        color: actionColor.withOpacity(0.10),
                        blurRadius: 14,
                        offset: const Offset(0, 7),
                      ),
                    ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: actionColor.withOpacity(0.12),
                      child: updatingStatus && !isCurrent
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              workflowIcon(status),
                              color: actionColor,
                              size: 20,
                            ),
                    ),
                    const Spacer(),
                    if (isCurrent)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: actionColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Current',
                          style: TextStyle(
                            color: actionColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: disabled ? Colors.grey : actionColor,
                      ),
                  ],
                ),

                const SizedBox(height: 12),

                Text(
                  workflowTitle(status),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: disabled ? Colors.grey.shade700 : darkText,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  workflowSubtitle(status),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 11,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget statusActions() {
    if (!canManageTicket || allowedStatuses.isEmpty) {
      return const SizedBox.shrink();
    }

    final currentStatus = ticket?['status']?.toString() ?? 'OPEN';
    final currentColor = workflowColor(currentStatus);

    final roleNote = isAssistant
        ? 'Assistant can dispatch tickets and move them between OPEN and IN_PROGRESS.'
        : isAgent
        ? 'Agent can update assigned maintenance work to IN_PROGRESS or RESOLVED.'
        : 'Admin and owner can control the full ticket workflow.';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: currentColor.withOpacity(0.12),
                  child: Icon(workflowIcon(currentStatus), color: currentColor),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Workflow Actions',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Current status: $currentStatus',
                        style: TextStyle(
                          color: currentColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: primary.withOpacity(0.08)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.verified_user, color: primary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      roleNote,
                      style: TextStyle(
                        color: Colors.grey.shade800,
                        height: 1.35,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (allowedStatuses.contains('IN_PROGRESS')) ...[
                    workflowActionButton(
                      label: 'Start',
                      status: 'IN_PROGRESS',
                      icon: Icons.play_arrow,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 10),
                  ],

                  if (allowedStatuses.contains('RESOLVED')) ...[
                    workflowActionButton(
                      label: 'Resolve',
                      status: 'RESOLVED',
                      icon: Icons.check,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 10),
                  ],

                  if (allowedStatuses.contains('CLOSED')) ...[
                    workflowActionButton(
                      label: 'Close',
                      status: 'CLOSED',
                      icon: Icons.lock,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 10),
                  ],

                  if (allowedStatuses.contains('OPEN')) ...[
                    workflowActionButton(
                      label: 'Reopen',
                      status: 'OPEN',
                      icon: Icons.refresh,
                      color: Colors.red,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget deleteCard() {
    if (!canDeleteTicket) return const SizedBox.shrink();

    return Card(
      color: Colors.red.withOpacity(0.06),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.delete_outline, color: Colors.red),
              title: Text(
                'Danger Zone',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                'Delete this ticket only if it was created by mistake.',
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: deleting ? null : deleteTicket,
                icon: deleting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.delete, color: Colors.red),
                label: Text(
                  deleting ? 'Deleting...' : 'Delete Ticket',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget messageStats() {
    return Row(
      children: [
        Expanded(
          child: miniCard(
            title: 'Tenant',
            value: tenantMessageCount.toString(),
            icon: Icons.person,
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: miniCard(
            title: 'Staff',
            value: staffMessageCount.toString(),
            icon: Icons.support_agent,
            color: primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: miniCard(
            title: 'Total',
            value: messageCount.toString(),
            icon: Icons.chat,
            color: Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget miniCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: darkText,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget messageCard(dynamic message) {
    final sender = message['sender'];
    final senderName = userName(sender);
    final senderRole = sender?['role']?.toString() ?? 'USER';
    final body = message['body']?.toString() ?? '';

    final fromTenant = senderRole == 'TENANT';
    final color = fromTenant ? Colors.green : primary;

    return Align(
      alignment: fromTenant ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: Card(
          color: fromTenant ? Colors.white : primary.withOpacity(0.08),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 17,
                      backgroundColor: color.withOpacity(0.12),
                      child: Icon(
                        fromTenant ? Icons.person : Icons.support_agent,
                        color: color,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        senderName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Text(
                      senderRole,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SelectableText(
                  body,
                  style: const TextStyle(fontSize: 15, height: 1.4),
                ),
                const SizedBox(height: 8),
                Text(
                  formatDate(message['createdAt']),
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget aiAssistantCard() {
    if (!canUseAiReply) {
      return const SizedBox.shrink();
    }

    return Card(
      color: primary.withOpacity(0.06),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: primary.withOpacity(0.12),
                  child: const Icon(Icons.auto_awesome, color: primary),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'AI Reply Helper',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Generate a professional reply using the latest tenant message and ticket context.',
              style: TextStyle(color: Colors.grey.shade700, height: 1.35),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: suggestingReply ? null : generateAiReply,
                icon: suggestingReply
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_fix_high),
                label: Text(
                  suggestingReply ? 'Generating...' : 'Suggest Reply with AI',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget replyComposer() {
    if (!canReply) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: messageCtrl,
              enabled: !sending,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Write a reply',
                hintText: 'Type your response to the tenant or team...',
                prefixIcon: Icon(Icons.message),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: hasDraftMessage
                        ? () {
                            messageCtrl.clear();
                            showSnack('Reply draft cleared');
                          }
                        : null,
                    icon: const Icon(Icons.clear),
                    label: const Text('Clear'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: sending || !hasDraftMessage ? null : sendMessage,
                    icon: sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                    label: Text(sending ? 'Sending...' : 'Send'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget conversationSection() {
    final list = messages();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        messageStats(),

        const SizedBox(height: 14),

        aiAssistantCard(),

        if (canUseAiReply) const SizedBox(height: 14),

        if (list.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(26),
              child: Column(
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 56,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'No messages yet',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Start the conversation by sending the first reply.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
          )
        else
          ...list.map(messageCard),

        const SizedBox(height: 14),

        replyComposer(),
      ],
    );
  }

  Widget overviewSection() {
    return Column(
      children: [
        summaryCard(),
        const SizedBox(height: 14),
        statusMeaningCard(),
        const SizedBox(height: 14),
        readOnlyNotice(),
        if (isTenant || isAssistant) const SizedBox(height: 14),
        messageStats(),
      ],
    );
  }

  Widget workflowSection() {
    return Column(
      children: [
        if (canAssignTicket) ...[assignmentCard(), const SizedBox(height: 14)],

        if (canManageTicket) ...[statusActions(), const SizedBox(height: 14)],

        statusMeaningCard(),

        const SizedBox(height: 14),

        deleteCard(),
      ],
    );
  }

  Widget selectedSectionBody() {
    if (selectedSection == 'CHAT') return conversationSection();
    if (selectedSection == 'WORKFLOW') return workflowSection();

    return overviewSection();
  }

  Widget loadingBody() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        SizedBox(height: 180),
        Center(child: CircularProgressIndicator()),
      ],
    );
  }

  Widget errorBody() {
    return RefreshIndicator(
      onRefresh: loadAll,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 120),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 42),
                  const SizedBox(height: 12),
                  const Text(
                    'Could not load ticket',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    onPressed: loadAll,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget emptyBody() {
    return RefreshIndicator(
      onRefresh: loadAll,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 150),
          Icon(Icons.construction, size: 64, color: Colors.grey.shade500),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              'Ticket not found',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget contentBody() {
    return RefreshIndicator(
      onRefresh: refreshTicket,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          heroHeader(),

          const SizedBox(height: 18),

          quickActions(),

          const SizedBox(height: 14),

          sectionSwitch(),

          const SizedBox(height: 14),

          selectedSectionBody(),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = isTenant
        ? 'My Request'
        : isAssistant
        ? 'Support Ticket'
        : 'Ticket Details';

    return Scaffold(
      backgroundColor: softBg,
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: refreshing
                ? const SizedBox(
                    width: 19,
                    height: 19,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            onPressed: refreshing ? null : refreshTicket,
          ),
          IconButton(
            icon: const Icon(Icons.insights),
            onPressed: ticket == null ? null : openTicketInsights,
          ),
          if (canDeleteTicket && ticket != null)
            IconButton(
              icon: deleting
                  ? const SizedBox(
                      width: 19,
                      height: 19,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_outline),
              onPressed: deleting ? null : deleteTicket,
            ),
        ],
      ),
      body: loading
          ? loadingBody()
          : error.isNotEmpty
          ? errorBody()
          : ticket == null
          ? emptyBody()
          : contentBody(),
    );
  }
}

class _AiReplySheet extends StatelessWidget {
  final String suggestedReply;
  final String category;
  final String urgency;
  final List<dynamic> quickReplies;
  final List<dynamic> nextActions;

  const _AiReplySheet({
    required this.suggestedReply,
    required this.category,
    required this.urgency,
    required this.quickReplies,
    required this.nextActions,
  });

  static const primary = Color(0xFF6750A4);
  static const softBg = Color(0xFFF8F5FF);

  Color urgencyColor() {
    switch (urgency) {
      case 'HIGH':
      case 'URGENT':
        return Colors.red;
      case 'MEDIUM':
        return Colors.orange;
      case 'LOW':
        return Colors.green;
      default:
        return primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = urgencyColor();

    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.55,
      maxChildSize: 0.96,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: softBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: SafeArea(
            top: false,
            child: ListView(
              controller: scrollController,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                CircleAvatar(
                  radius: 34,
                  backgroundColor: primary.withOpacity(0.12),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: primary,
                    size: 34,
                  ),
                ),

                const SizedBox(height: 14),

                const Text(
                  'AI Suggested Reply',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 6),

                Text(
                  'Review, copy, or use the generated reply.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade700),
                ),

                const SizedBox(height: 16),

                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(
                      label: Text(category),
                      backgroundColor: primary.withOpacity(0.12),
                      labelStyle: const TextStyle(
                        color: primary,
                        fontWeight: FontWeight.bold,
                      ),
                      side: BorderSide.none,
                    ),
                    Chip(
                      label: Text(urgency),
                      backgroundColor: color.withOpacity(0.12),
                      labelStyle: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                      side: BorderSide.none,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SelectableText(
                      suggestedReply,
                      style: const TextStyle(fontSize: 15, height: 1.45),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(text: suggestedReply),
                          );

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Reply copied')),
                            );
                          }
                        },
                        icon: const Icon(Icons.copy),
                        label: const Text('Copy'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context, suggestedReply),
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Use Reply'),
                      ),
                    ),
                  ],
                ),

                if (quickReplies.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  const Text(
                    'Quick Replies',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...quickReplies.map((reply) {
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.reply, color: primary),
                        title: Text(reply.toString()),
                        onTap: () => Navigator.pop(context, reply.toString()),
                      ),
                    );
                  }),
                ],

                if (nextActions.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  const Text(
                    'Recommended Next Actions',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...nextActions.map((action) {
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.checklist, color: primary),
                        title: Text(action.toString()),
                      ),
                    );
                  }),
                ],

                const SizedBox(height: 12),

                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TicketInsightsSheet extends StatelessWidget {
  final String title;
  final String status;
  final String priority;
  final int healthScore;
  final String healthLabel;
  final Color healthColor;
  final int progressPercent;
  final int messageCount;
  final int tenantMessageCount;
  final int staffMessageCount;
  final String assignedName;
  final String ageLabel;
  final String propertyName;
  final String unitName;

  const _TicketInsightsSheet({
    required this.title,
    required this.status,
    required this.priority,
    required this.healthScore,
    required this.healthLabel,
    required this.healthColor,
    required this.progressPercent,
    required this.messageCount,
    required this.tenantMessageCount,
    required this.staffMessageCount,
    required this.assignedName,
    required this.ageLabel,
    required this.propertyName,
    required this.unitName,
  });

  static const primary = Color(0xFF6750A4);
  static const softBg = Color(0xFFF8F5FF);

  Widget scoreCard({
    required String title,
    required int value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      color: color.withOpacity(0.07),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withOpacity(0.12),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Text(
                  '$value%',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: value / 100,
                minHeight: 8,
                backgroundColor: Colors.white,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget infoRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 128,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value?.toString().isNotEmpty == true ? value.toString() : '—',
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.55,
      maxChildSize: 0.96,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: softBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: SafeArea(
            top: false,
            child: ListView(
              controller: scrollController,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                CircleAvatar(
                  radius: 36,
                  backgroundColor: healthColor.withOpacity(0.12),
                  child: Icon(Icons.insights, color: healthColor, size: 36),
                ),

                const SizedBox(height: 14),

                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  '$propertyName • $unitName',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade700),
                ),

                const SizedBox(height: 16),

                Chip(
                  avatar: Icon(
                    Icons.health_and_safety,
                    color: healthColor,
                    size: 18,
                  ),
                  label: Text(healthLabel),
                  backgroundColor: healthColor.withOpacity(0.12),
                  labelStyle: TextStyle(
                    color: healthColor,
                    fontWeight: FontWeight.bold,
                  ),
                  side: BorderSide.none,
                ),

                const SizedBox(height: 18),

                scoreCard(
                  title: 'Ticket Health',
                  value: healthScore,
                  icon: Icons.health_and_safety,
                  color: healthColor,
                ),

                const SizedBox(height: 10),

                scoreCard(
                  title: 'Workflow Progress',
                  value: progressPercent,
                  icon: Icons.timeline,
                  color: progressPercent >= 85
                      ? Colors.green
                      : progressPercent >= 55
                      ? Colors.orange
                      : primary,
                ),

                const SizedBox(height: 14),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        infoRow('Status', status),
                        infoRow('Priority', priority),
                        infoRow('Assigned To', assignedName),
                        infoRow('Age', ageLabel),
                        infoRow('Messages', messageCount),
                        infoRow('Tenant Messages', tenantMessageCount),
                        infoRow('Staff Messages', staffMessageCount),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                Card(
                  color: primary.withOpacity(0.07),
                  child: ListTile(
                    leading: const Icon(
                      Icons.lightbulb_outline,
                      color: primary,
                    ),
                    title: const Text(
                      'Operational note',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      healthLabel == 'Unassigned'
                          ? 'Assign this ticket to a responsible team member so the tenant knows who is handling it.'
                          : healthLabel == 'Urgent'
                          ? 'Urgent tickets need quick updates and clear communication.'
                          : healthLabel == 'Aging'
                          ? 'This ticket has been open for several days and should be reviewed.'
                          : 'Keep the tenant informed with clear replies and move the ticket through the workflow.',
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SafeActionSheet extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String message;
  final String confirmText;

  const _SafeActionSheet({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
    required this.confirmText,
  });

  static const softBg = Color(0xFFF8F5FF);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: softBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),

              const SizedBox(height: 22),

              CircleAvatar(
                radius: 32,
                backgroundColor: color.withOpacity(0.12),
                child: Icon(icon, color: color, size: 34),
              ),

              const SizedBox(height: 16),

              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700, height: 1.45),
              ),

              const SizedBox(height: 22),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.pop(context, true),
                  icon: Icon(icon),
                  label: Text(confirmText),
                ),
              ),

              const SizedBox(height: 8),

              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
