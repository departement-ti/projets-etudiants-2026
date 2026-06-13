import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/auth/auth_storage.dart';
import '../../core/ui/app_error.dart';
import 'ai_service.dart';

class AiAssistantPage extends StatefulWidget {
  const AiAssistantPage({super.key});

  @override
  State<AiAssistantPage> createState() => _AiAssistantPageState();
}

class _AiAssistantPageState extends State<AiAssistantPage> {
  static const primary = Color(0xFF6750A4);
  static const softBg = Color(0xFFF8F5FF);
  static const darkText = Color(0xFF1D1B20);
  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF97316);
  static const danger = Color(0xFFEF4444);
  static const info = Color(0xFF0EA5E9);
  static const purple = Color(0xFF8B5CF6);

  String? role;

  bool roleLoading = true;
  bool loadingTenants = true;
  bool refreshing = false;

  bool generating360 = false;
  bool predicting = false;
  bool scoring = false;
  bool sendingTenantMessage = false;

  String error = '';
  String selectedTool = 'TENANT_360';

  List<dynamic> tenants = [];

  String? selectedTenantId;
  String? selectedRentDelayTenantId;
  String? selectedRiskTenantId;

  Map<String, dynamic>? tenant360Result;
  Map<String, dynamic>? rentDelayResult;
  Map<String, dynamic>? riskResult;

  final tenantNameCtrl = TextEditingController(text: 'Demo Tenant');
  final rentAmountCtrl = TextEditingController(text: '400');
  final previousLatePaymentsCtrl = TextEditingController(text: '2');
  final openTicketsCtrl = TextEditingController(text: '1');
  final unpaidAmountCtrl = TextEditingController(text: '100');

  final riskTenantNameCtrl = TextEditingController(text: 'Demo Tenant');
  final latePaymentsCtrl = TextEditingController(text: '2');
  final riskUnpaidAmountCtrl = TextEditingController(text: '100');
  final ticketsCountCtrl = TextEditingController(text: '1');
  final leaseMonthsCtrl = TextEditingController(text: '12');

  bool get isAssistant => role == 'ASSISTANT';

  bool get hasTenants => tenants.isNotEmpty;

  bool get busy {
    return roleLoading ||
        loadingTenants ||
        refreshing ||
        generating360 ||
        predicting ||
        scoring ||
        sendingTenantMessage;
  }

  int get tenantCount => tenants.length;

  int get completedSignals {
    int count = 0;

    if (selectedTenantId != null) count++;
    if (tenant360Result != null) count++;
    if (rentDelayResult != null) count++;
    if (riskResult != null) count++;

    return count;
  }

  int get readinessPercent {
    return ((completedSignals / 4) * 100).round();
  }

  String get selectedTenantName {
    return tenantNameById(selectedTenantId);
  }

  String get selectedToolTitle {
    switch (selectedTool) {
      case 'RENT_DELAY':
        return 'Rent Delay Prediction';
      case 'RISK_SCORE':
        return 'Tenant Risk Score';
      case 'TENANT_360':
      default:
        return 'Tenant 360 Intelligence';
    }
  }

  String get selectedToolSubtitle {
    switch (selectedTool) {
      case 'RENT_DELAY':
        return 'Predict payment delay risk using tenant history and current signals.';
      case 'RISK_SCORE':
        return 'Score reliability using late payments, unpaid balance and maintenance load.';
      case 'TENANT_360':
      default:
        return 'Generate a complete tenant profile from leases, invoices, payments and tickets.';
    }
  }

  IconData get selectedToolIcon {
    switch (selectedTool) {
      case 'RENT_DELAY':
        return Icons.psychology;
      case 'RISK_SCORE':
        return Icons.analytics;
      case 'TENANT_360':
      default:
        return Icons.manage_search;
    }
  }

  @override
  void initState() {
    super.initState();
    loadInitialData();
  }

  @override
  void dispose() {
    tenantNameCtrl.dispose();
    rentAmountCtrl.dispose();
    previousLatePaymentsCtrl.dispose();
    openTicketsCtrl.dispose();
    unpaidAmountCtrl.dispose();

    riskTenantNameCtrl.dispose();
    latePaymentsCtrl.dispose();
    riskUnpaidAmountCtrl.dispose();
    ticketsCountCtrl.dispose();
    leaseMonthsCtrl.dispose();

    super.dispose();
  }

  Future<void> loadInitialData() async {
    setState(() {
      roleLoading = true;
      loadingTenants = true;
      error = '';
    });

    try {
      final userRole = await AuthStorage.getUserRole();

      if (!mounted) return;

      setState(() {
        role = userRole;
        roleLoading = false;
      });

      if (userRole == 'ASSISTANT') {
        setState(() => loadingTenants = false);
        return;
      }

      await loadTenants(showErrorSheet: false);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = AppError.clean(e);
        roleLoading = false;
        loadingTenants = false;
      });
    }
  }

  Future<void> refreshPage() async {
    if (refreshing) return;

    setState(() => refreshing = true);

    try {
      await loadInitialData();
    } finally {
      if (mounted) {
        setState(() => refreshing = false);
      }
    }
  }

  Future<void> loadTenants({bool showErrorSheet = true}) async {
    setState(() {
      loadingTenants = true;
      error = '';
    });

    try {
      final data = await AiService.getTenants();

      if (!mounted) return;

      setState(() {
        tenants = data;

        if (data.isNotEmpty) {
          final firstId = data.first['id']?.toString();

          selectedTenantId = firstId;
          selectedRentDelayTenantId = firstId;
          selectedRiskTenantId = firstId;

          final firstTenantName = tenantLabel(data.first);
          tenantNameCtrl.text = firstTenantName;
          riskTenantNameCtrl.text = firstTenantName;
        } else {
          selectedTenantId = null;
          selectedRentDelayTenantId = null;
          selectedRiskTenantId = null;
        }

        loadingTenants = false;
      });

      final firstTenantId = data.isNotEmpty
          ? data.first['id']?.toString()
          : null;

      if (firstTenantId != null && firstTenantId.isNotEmpty) {
        await fillManualAiFieldsFromTenant(firstTenantId, showSheet: false);
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = AppError.clean(e);
        loadingTenants = false;
      });

      if (showErrorSheet) {
        await AppError.show(context, e, title: 'Could not load tenants');
      }
    }
  }

  Future<void> selectTenant(String tenantId, {bool loadSignals = true}) async {
    setState(() {
      selectedTenantId = tenantId;
      selectedRentDelayTenantId = tenantId;
      selectedRiskTenantId = tenantId;

      tenant360Result = null;
      rentDelayResult = null;
      riskResult = null;

      final tenantName = tenantNameById(tenantId);
      tenantNameCtrl.text = tenantName;
      riskTenantNameCtrl.text = tenantName;
    });

    if (loadSignals) {
      await fillManualAiFieldsFromTenant(tenantId);
    }
  }

  Future<void> fillManualAiFieldsFromTenant(
    String tenantId, {
    bool showSheet = true,
  }) async {
    if (tenantId.isEmpty) return;

    setState(() => error = '');

    try {
      final result = await AiService.tenant360(tenantId);

      if (!mounted) return;

      fillFieldsFromTenant360Result(result);
    } catch (e) {
      if (!mounted) return;

      setState(() => error = AppError.clean(e));

      if (showSheet) {
        await AppError.show(context, e, title: 'Could not load tenant AI data');
      }
    }
  }

  void fillFieldsFromTenant360Result(Map<String, dynamic> result) {
    final lease = result['lease'];
    final financials = result['financials'] ?? {};
    final maintenance = result['maintenance'] ?? {};

    final totalUnpaid = financials['totalUnpaid']?.toString() ?? '0';
    final openTickets = maintenance['openTickets']?.toString() ?? '0';
    final latePaidInvoices = financials['latePaidInvoices']?.toString() ?? '0';

    setState(() {
      rentAmountCtrl.text = lease?['rentAmount']?.toString() ?? '0';
      previousLatePaymentsCtrl.text = latePaidInvoices;
      openTicketsCtrl.text = openTickets;
      unpaidAmountCtrl.text = totalUnpaid;

      latePaymentsCtrl.text = latePaidInvoices;
      riskUnpaidAmountCtrl.text = totalUnpaid;
      ticketsCountCtrl.text = openTickets;
      leaseMonthsCtrl.text = leaseMonthsFromLease(lease).toString();
    });
  }

  int leaseMonthsFromLease(dynamic lease) {
    if (lease == null) return 12;

    final start = DateTime.tryParse(lease['startDate']?.toString() ?? '');
    final end = DateTime.tryParse(lease['endDate']?.toString() ?? '');

    if (start == null || end == null) return 12;

    final months = ((end.year - start.year) * 12) + (end.month - start.month);

    return months <= 0 ? 1 : months;
  }

  Future<void> generateTenant360ForTenant(String tenantId) async {
    if (tenantId.isEmpty) {
      await AppError.show(
        context,
        'Please select a tenant before generating Tenant 360.',
        title: 'Tenant required',
      );
      return;
    }

    setState(() {
      selectedTenantId = tenantId;
      selectedRentDelayTenantId = tenantId;
      selectedRiskTenantId = tenantId;

      generating360 = true;
      error = '';
      tenant360Result = null;
      rentDelayResult = null;
      riskResult = null;

      final tenantName = tenantNameById(tenantId);
      tenantNameCtrl.text = tenantName;
      riskTenantNameCtrl.text = tenantName;
    });

    try {
      final result = await AiService.tenant360(tenantId);

      if (!mounted) return;

      setState(() => tenant360Result = result);
      fillFieldsFromTenant360Result(result);

      showSnack('Tenant 360 generated');
    } catch (e) {
      if (!mounted) return;

      setState(() => error = AppError.clean(e));
      await AppError.show(context, e, title: 'Could not generate Tenant 360');
    } finally {
      if (mounted) {
        setState(() => generating360 = false);
      }
    }
  }

  Future<void> generateTenant360() async {
    final tenantId = selectedTenantId;

    if (tenantId == null || tenantId.isEmpty) {
      await AppError.show(
        context,
        'Please select a tenant before generating Tenant 360.',
        title: 'Tenant required',
      );
      return;
    }

    await generateTenant360ForTenant(tenantId);
  }

  Future<void> predictRentDelay() async {
    final tenantId = selectedRentDelayTenantId;

    if (tenantId == null || tenantId.isEmpty) {
      await AppError.show(
        context,
        'Please select a tenant before running prediction.',
        title: 'Tenant required',
      );
      return;
    }

    final tenantName = tenantNameById(tenantId);

    setState(() {
      predicting = true;
      error = '';
      rentDelayResult = null;
      tenantNameCtrl.text = tenantName;
    });

    try {
      final result = await AiService.predictRentDelay(
        tenantName: tenantName,
        rentAmount: number(rentAmountCtrl),
        previousLatePayments: integer(previousLatePaymentsCtrl),
        openTickets: integer(openTicketsCtrl),
        unpaidAmount: number(unpaidAmountCtrl),
      );

      if (!mounted) return;

      setState(() => rentDelayResult = result);
      showSnack('Rent delay prediction completed');
    } catch (e) {
      if (!mounted) return;

      setState(() => error = AppError.clean(e));
      await AppError.show(context, e, title: 'Could not predict rent delay');
    } finally {
      if (mounted) {
        setState(() => predicting = false);
      }
    }
  }

  Future<void> scoreRisk() async {
    final tenantId = selectedRiskTenantId;

    if (tenantId == null || tenantId.isEmpty) {
      await AppError.show(
        context,
        'Please select a tenant before scoring risk.',
        title: 'Tenant required',
      );
      return;
    }

    final tenantName = tenantNameById(tenantId);

    setState(() {
      scoring = true;
      error = '';
      riskResult = null;
      riskTenantNameCtrl.text = tenantName;
    });

    try {
      final result = await AiService.scoreTenantRisk(
        tenantName: tenantName,
        latePayments: integer(latePaymentsCtrl),
        unpaidAmount: number(riskUnpaidAmountCtrl),
        ticketsCount: integer(ticketsCountCtrl),
        leaseMonths: integer(leaseMonthsCtrl),
      );

      if (!mounted) return;

      setState(() => riskResult = result);
      showSnack('Tenant risk score completed');
    } catch (e) {
      if (!mounted) return;

      setState(() => error = AppError.clean(e));
      await AppError.show(context, e, title: 'Could not score tenant risk');
    } finally {
      if (mounted) {
        setState(() => scoring = false);
      }
    }
  }

  Future<void> sendSuggestedMessage(String message) async {
    final tenantId = selectedTenantId;

    if (tenantId == null || tenantId.isEmpty) {
      await AppError.show(
        context,
        'Please select a tenant first.',
        title: 'Tenant required',
      );
      return;
    }

    if (message.trim().isEmpty) {
      await AppError.show(
        context,
        'The suggested tenant message is empty.',
        title: 'Message required',
      );
      return;
    }

    final confirmed = await confirmSendTenantMessage(message);

    if (!confirmed) return;

    setState(() => sendingTenantMessage = true);

    try {
      await AiService.sendTenant360Message(
        tenantId: tenantId,
        message: message.trim(),
      );

      if (!mounted) return;

      showSnack('Message sent to tenant');
    } catch (e) {
      if (!mounted) return;

      await AppError.show(context, e, title: 'Could not send tenant message');
    } finally {
      if (mounted) {
        setState(() => sendingTenantMessage = false);
      }
    }
  }

  Future<bool> confirmSendTenantMessage(String message) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return _ConfirmMessageSheet(
          tenantName: tenantNameById(selectedTenantId),
          message: message,
        );
      },
    );

    return confirmed == true;
  }

  double number(TextEditingController controller) {
    return double.tryParse(controller.text.trim()) ?? 0;
  }

  int integer(TextEditingController controller) {
    return int.tryParse(controller.text.trim()) ?? 0;
  }

  String formatDate(dynamic value) {
    if (value == null) return '—';

    final parsed = DateTime.tryParse(value.toString());
    if (parsed == null) return value.toString();

    return parsed.toLocal().toString().split(' ')[0];
  }

  void showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String tenantLabel(dynamic tenant) {
    final user = tenant['user'];

    if (user != null) {
      final firstName = user['firstName']?.toString() ?? '';
      final lastName = user['lastName']?.toString() ?? '';
      final email = user['email']?.toString() ?? '';

      final fullName = '$firstName $lastName'.trim();

      if (fullName.isNotEmpty) return fullName;
      if (email.isNotEmpty) return email;
    }

    return 'Tenant';
  }

  String tenantEmail(dynamic tenant) {
    final user = tenant['user'];
    return user?['email']?.toString() ?? '—';
  }

  String tenantNameById(String? tenantId) {
    if (tenantId == null) return 'Tenant';

    for (final tenant in tenants) {
      if (tenant['id']?.toString() == tenantId) {
        return tenantLabel(tenant);
      }
    }

    return 'Tenant';
  }

  dynamic tenantById(String? tenantId) {
    if (tenantId == null) return null;

    for (final tenant in tenants) {
      if (tenant['id']?.toString() == tenantId) return tenant;
    }

    return null;
  }

  Color riskColor(String? value) {
    switch (value) {
      case 'CRITICAL':
      case 'HIGH':
        return danger;
      case 'ELEVATED':
      case 'MEDIUM':
        return warning;
      case 'LOW':
      case 'NORMAL':
        return success;
      default:
        return primary;
    }
  }

  IconData riskIcon(String? value) {
    switch (value) {
      case 'CRITICAL':
      case 'HIGH':
        return Icons.priority_high;
      case 'ELEVATED':
      case 'MEDIUM':
        return Icons.warning_amber;
      case 'LOW':
      case 'NORMAL':
        return Icons.check_circle;
      default:
        return Icons.auto_awesome;
    }
  }

  Color toolColor(String tool) {
    switch (tool) {
      case 'TENANT_360':
        return primary;
      case 'RENT_DELAY':
        return info;
      case 'RISK_SCORE':
        return purple;
      default:
        return primary;
    }
  }

  IconData toolIcon(String tool) {
    switch (tool) {
      case 'TENANT_360':
        return Icons.manage_search;
      case 'RENT_DELAY':
        return Icons.psychology;
      case 'RISK_SCORE':
        return Icons.analytics;
      default:
        return Icons.auto_awesome;
    }
  }

  String toolLabel(String tool) {
    switch (tool) {
      case 'TENANT_360':
        return 'Tenant 360';
      case 'RENT_DELAY':
        return 'Rent Delay';
      case 'RISK_SCORE':
        return 'Risk Score';
      default:
        return tool;
    }
  }

  String toolDescription(String tool) {
    switch (tool) {
      case 'TENANT_360':
        return 'Full AI tenant profile';
      case 'RENT_DELAY':
        return 'Payment delay prediction';
      case 'RISK_SCORE':
        return 'Reliability scoring';
      default:
        return '';
    }
  }

  Map<String, dynamic> resultSummary(Map<String, dynamic>? result) {
    if (result == null) return {};

    final score =
        result['riskScore'] ??
        result['score'] ??
        result['probability'] ??
        result['delayProbability'] ??
        0;

    final badge =
        result['riskLevel'] ??
        result['category'] ??
        result['level'] ??
        result['status'] ??
        'AI';

    final summary =
        result['summary'] ??
        result['message'] ??
        result['prediction'] ??
        result['managementSummary'] ??
        '';

    return {
      'score': score,
      'badge': badge.toString(),
      'summary': summary.toString(),
    };
  }

  Future<void> openTenant360Details() async {
    final result = tenant360Result;
    if (result == null) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _Tenant360Sheet(
        result: result,
        tenantName: selectedTenantName,
        formatDate: formatDate,
        riskColor: riskColor,
        riskIcon: riskIcon,
        onCopyMessage: copyText,
        onSendMessage: sendSuggestedMessage,
      ),
    );
  }

  Future<void> openSimpleResultDetails({
    required String title,
    required Map<String, dynamic>? result,
    required String badgeKey,
    required String itemsKey,
    required String actionsKey,
  }) async {
    if (result == null) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AiResultSheet(
        title: title,
        result: result,
        badgeKey: badgeKey,
        itemsKey: itemsKey,
        actionsKey: actionsKey,
        riskColor: riskColor,
        riskIcon: riskIcon,
        onCopy: copyText,
      ),
    );
  }

  Future<void> copyText(String text) async {
    await Clipboard.setData(ClipboardData(text: text));

    if (!mounted) return;

    showSnack('Copied');
  }

  Widget heroHeader() {
    final color = readinessPercent >= 75
        ? success
        : readinessPercent >= 40
        ? warning
        : Colors.white;

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
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 31,
                backgroundColor: Colors.white,
                child: Icon(Icons.auto_awesome, color: primary, size: 31),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Smart Assistant',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 27,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Tenant intelligence and predictive risk tools.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: refreshing ? null : refreshPage,
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
          Row(
            children: [
              Expanded(
                child: heroMetric(
                  title: 'Tenants',
                  value: tenantCount.toString(),
                  icon: Icons.groups,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: heroMetric(
                  title: 'AI Readiness',
                  value: '$readinessPercent%',
                  icon: Icons.auto_graph,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: readinessPercent / 100,
              minHeight: 9,
              backgroundColor: Colors.white24,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withOpacity(0.18)),
            ),
            child: Row(
              children: [
                const Icon(Icons.psychology, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    hasTenants
                        ? '$selectedTenantName is selected for AI analysis.'
                        : 'Create tenant profiles to unlock AI intelligence.',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
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
              fontSize: 19,
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

  Widget toolCards() {
    final tools = ['TENANT_360', 'RENT_DELAY', 'RISK_SCORE'];

    return SizedBox(
      height: 132,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: tools.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, index) {
          final tool = tools[index];
          final selected = selectedTool == tool;
          final color = toolColor(tool);

          return SizedBox(
            width: 168,
            child: Material(
              color: selected ? color : Colors.white,
              borderRadius: BorderRadius.circular(24),
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () => setState(() => selectedTool = tool),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: selected ? color : Colors.black.withOpacity(0.04),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: selected
                            ? color.withOpacity(0.20)
                            : Colors.black.withOpacity(0.025),
                        blurRadius: 14,
                        offset: const Offset(0, 7),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        backgroundColor: selected
                            ? Colors.white.withOpacity(0.18)
                            : color.withOpacity(0.12),
                        child: Icon(
                          toolIcon(tool),
                          color: selected ? Colors.white : color,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        toolLabel(tool),
                        style: TextStyle(
                          color: selected ? Colors.white : darkText,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        toolDescription(tool),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: selected
                              ? Colors.white70
                              : Colors.grey.shade700,
                          fontSize: 12,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget selectedToolHeader() {
    final color = toolColor(selectedTool);

    return Card(
      color: color.withOpacity(0.07),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.12),
              child: Icon(selectedToolIcon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selectedToolTitle,
                    style: TextStyle(
                      color: color,
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    selectedToolSubtitle,
                    style: TextStyle(color: Colors.grey.shade800, height: 1.35),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget tenantSelectorCard() {
    if (loadingTenants) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(18),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (tenants.isEmpty) return noTenantsCard();

    final validValue =
        tenants.any((tenant) {
          return tenant['id']?.toString() == selectedTenantId;
        })
        ? selectedTenantId
        : null;

    final selectedTenant = tenantById(selectedTenantId);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: validValue,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'AI Tenant Context',
                prefixIcon: Icon(Icons.person_search),
              ),
              items: tenants.map((tenant) {
                return DropdownMenuItem<String>(
                  value: tenant['id']?.toString(),
                  child: Text(
                    tenantLabel(tenant),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: busy
                  ? null
                  : (value) {
                      if (value == null) return;
                      selectTenant(value);
                    },
            ),
            if (selectedTenant != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: softBg,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: primary.withOpacity(0.12),
                      child: Text(
                        tenantInitials(selectedTenant),
                        style: const TextStyle(
                          color: primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tenantLabel(selectedTenant),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            tenantEmail(selectedTenant),
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Generate Tenant 360',
                      onPressed: generating360 ? null : generateTenant360,
                      icon: generating360
                          ? const SizedBox(
                              width: 19,
                              height: 19,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.auto_awesome),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String tenantInitials(dynamic tenant) {
    final name = tenantLabel(tenant).trim();

    if (name.isEmpty) return 'T';

    final parts = name
        .split(' ')
        .where((part) => part.trim().isNotEmpty)
        .toList();

    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }

    return name[0].toUpperCase();
  }

  Widget noTenantsCard() {
    return Card(
      color: warning.withOpacity(0.10),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: warning.withOpacity(0.12),
              child: const Icon(Icons.warning_amber, color: warning),
            ),
            const SizedBox(height: 14),
            const Text(
              'No tenant profiles found',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Create tenant profiles first, then return to generate Tenant 360, rent delay predictions and risk scores.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget errorCard() {
    if (error.isEmpty) return const SizedBox.shrink();

    return Card(
      color: Colors.red.withOpacity(0.08),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                error,
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget aiButton({
    required bool loading,
    required String loadingText,
    required String text,
    required IconData icon,
    required VoidCallback onPressed,
    Color? color,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: loading || loadingTenants || tenants.isEmpty
            ? null
            : onPressed,
        style: color == null
            ? null
            : ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
              ),
        icon: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icon),
        label: Text(loading ? loadingText : text),
      ),
    );
  }

  Widget inputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      enabled: !busy,
      keyboardType: keyboardType,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
    );
  }

  Widget tenant360Tool() {
    return Column(
      children: [
        selectedToolHeader(),
        const SizedBox(height: 12),
        tenantSelectorCard(),
        const SizedBox(height: 12),
        aiButton(
          loading: generating360,
          loadingText: 'Generating Tenant 360...',
          text: 'Generate Tenant 360',
          icon: Icons.auto_awesome,
          color: primary,
          onPressed: generateTenant360,
        ),
        const SizedBox(height: 14),
        tenant360CompactReport(),
      ],
    );
  }

  Widget tenant360CompactReport() {
    final data = tenant360Result;
    if (data == null) {
      return helperCard(
        icon: Icons.manage_search,
        color: primary,
        title: 'Tenant 360 not generated yet',
        text:
            'Select a tenant and generate a full profile. The result will automatically fill the Rent Delay and Risk Score tools.',
      );
    }

    final tenant = data['tenant'] ?? {};
    final financials = data['financials'] ?? {};
    final maintenance = data['maintenance'] ?? {};
    final ai = data['ai'] ?? {};

    final riskLevel = ai['riskLevel']?.toString() ?? 'UNKNOWN';
    final riskScore = ai['riskScore']?.toString() ?? '0';
    final color = riskColor(riskLevel);

    return Column(
      children: [
        Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: openTenant360Details,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 31,
                        backgroundColor: color.withOpacity(0.12),
                        child: Icon(riskIcon(riskLevel), color: color),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tenant['name']?.toString() ?? selectedTenantName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: darkText,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              tenant['email']?.toString() ??
                                  'Tenant AI profile',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.grey.shade700),
                            ),
                          ],
                        ),
                      ),
                      Chip(
                        avatar: Icon(
                          riskIcon(riskLevel),
                          color: color,
                          size: 16,
                        ),
                        label: Text(riskLevel),
                        backgroundColor: color.withOpacity(0.12),
                        labelStyle: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                        side: BorderSide.none,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: compactMetric(
                          title: 'Risk',
                          value: '$riskScore/100',
                          icon: Icons.health_and_safety,
                          color: color,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: compactMetric(
                          title: 'Unpaid',
                          value: financials['totalUnpaid']?.toString() ?? '0',
                          icon: Icons.warning_amber,
                          color: warning,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: compactMetric(
                          title: 'Tickets',
                          value: maintenance['openTickets']?.toString() ?? '0',
                          icon: Icons.construction,
                          color: danger,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      ai['managementSummary']?.toString() ??
                          'Tenant 360 profile generated successfully.',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade800,
                        height: 1.35,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: openTenant360Details,
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Open Full Tenant 360 Report'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        suggestedMessageCompact(ai['suggestedMessage']?.toString() ?? ''),
      ],
    );
  }

  Widget compactMetric({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 21),
          const SizedBox(height: 7),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
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

  Widget suggestedMessageCompact(String message) {
    if (message.trim().isEmpty) return const SizedBox.shrink();

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
                  child: const Icon(Icons.mark_email_read, color: primary),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Suggested Tenant Message',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                message,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey.shade800, height: 1.35),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => copyText(message),
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: sendingTenantMessage
                        ? null
                        : () => sendSuggestedMessage(message),
                    icon: sendingTenantMessage
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                    label: Text(sendingTenantMessage ? 'Sending...' : 'Send'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget rentDelayTool() {
    return Column(
      children: [
        selectedToolHeader(),
        const SizedBox(height: 12),
        tenantSignalSelector(
          label: 'Prediction Tenant',
          value: selectedRentDelayTenantId,
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              selectedRentDelayTenantId = value;
              selectedTenantId = value;
              tenantNameCtrl.text = tenantNameById(value);
              rentDelayResult = null;
            });
            fillManualAiFieldsFromTenant(value);
          },
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                inputField(
                  controller: tenantNameCtrl,
                  label: 'Tenant Name',
                  icon: Icons.person,
                ),
                const SizedBox(height: 12),
                inputField(
                  controller: rentAmountCtrl,
                  label: 'Rent Amount',
                  icon: Icons.payments,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                inputField(
                  controller: previousLatePaymentsCtrl,
                  label: 'Previous Late Payments',
                  icon: Icons.history,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                inputField(
                  controller: openTicketsCtrl,
                  label: 'Open Tickets',
                  icon: Icons.construction,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                inputField(
                  controller: unpaidAmountCtrl,
                  label: 'Current Unpaid Amount',
                  icon: Icons.warning_amber,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                aiButton(
                  loading: predicting,
                  loadingText: 'Predicting...',
                  text: 'Predict Rent Delay',
                  icon: Icons.psychology,
                  color: info,
                  onPressed: predictRentDelay,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        simpleResultPanel(
          result: rentDelayResult,
          title: 'Prediction Result',
          badgeKey: 'riskLevel',
          itemsKey: 'explanation',
          actionsKey: 'recommendations',
          onOpen: () => openSimpleResultDetails(
            title: 'Prediction Result',
            result: rentDelayResult,
            badgeKey: 'riskLevel',
            itemsKey: 'explanation',
            actionsKey: 'recommendations',
          ),
        ),
      ],
    );
  }

  Widget riskScoreTool() {
    return Column(
      children: [
        selectedToolHeader(),
        const SizedBox(height: 12),
        tenantSignalSelector(
          label: 'Risk Score Tenant',
          value: selectedRiskTenantId,
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              selectedRiskTenantId = value;
              selectedTenantId = value;
              riskTenantNameCtrl.text = tenantNameById(value);
              riskResult = null;
            });
            fillManualAiFieldsFromTenant(value);
          },
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                inputField(
                  controller: riskTenantNameCtrl,
                  label: 'Tenant Name',
                  icon: Icons.person,
                ),
                const SizedBox(height: 12),
                inputField(
                  controller: latePaymentsCtrl,
                  label: 'Late Payments',
                  icon: Icons.history,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                inputField(
                  controller: riskUnpaidAmountCtrl,
                  label: 'Unpaid Amount',
                  icon: Icons.warning,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                inputField(
                  controller: ticketsCountCtrl,
                  label: 'Tickets Count',
                  icon: Icons.construction,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                inputField(
                  controller: leaseMonthsCtrl,
                  label: 'Lease Duration Months',
                  icon: Icons.date_range,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                aiButton(
                  loading: scoring,
                  loadingText: 'Scoring...',
                  text: 'Score Tenant Risk',
                  icon: Icons.analytics,
                  color: purple,
                  onPressed: scoreRisk,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        simpleResultPanel(
          result: riskResult,
          title: 'Tenant Risk Score',
          badgeKey: 'category',
          itemsKey: 'strengths',
          actionsKey: 'recommendedActions',
          onOpen: () => openSimpleResultDetails(
            title: 'Tenant Risk Score',
            result: riskResult,
            badgeKey: 'category',
            itemsKey: 'strengths',
            actionsKey: 'recommendedActions',
          ),
        ),
      ],
    );
  }

  Widget tenantSignalSelector({
    required String label,
    required String? value,
    required ValueChanged<String?> onChanged,
  }) {
    if (loadingTenants) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (tenants.isEmpty) return noTenantsCard();

    final validValue =
        tenants.any((tenant) {
          return tenant['id']?.toString() == value;
        })
        ? value
        : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: DropdownButtonFormField<String>(
          value: validValue,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: const Icon(Icons.person_search),
          ),
          items: tenants.map((tenant) {
            return DropdownMenuItem<String>(
              value: tenant['id']?.toString(),
              child: Text(
                tenantLabel(tenant),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: busy ? null : onChanged,
        ),
      ),
    );
  }

  Widget simpleResultPanel({
    required Map<String, dynamic>? result,
    required String title,
    required String badgeKey,
    required String itemsKey,
    required String actionsKey,
    required VoidCallback onOpen,
  }) {
    if (result == null) {
      return helperCard(
        icon: Icons.auto_awesome,
        color: toolColor(selectedTool),
        title: '$title not generated yet',
        text: 'Run the selected AI tool to generate this result.',
      );
    }

    final badge = result[badgeKey]?.toString() ?? 'AI';
    final color = riskColor(badge);
    final summary = resultSummary(result);
    final score = summary['score']?.toString() ?? '0';
    final text = summary['summary']?.toString() ?? '';

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: color.withOpacity(0.12),
                    child: Icon(riskIcon(badge), color: color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Chip(
                    label: Text(badge),
                    backgroundColor: color.withOpacity(0.12),
                    labelStyle: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                    side: BorderSide.none,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Text(
                    score,
                    style: TextStyle(
                      color: color,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('/ 100', style: TextStyle(color: Colors.grey.shade700)),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: onOpen,
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Details'),
                  ),
                ],
              ),
              if (text.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    text,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade800, height: 1.35),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget helperCard({
    required IconData icon,
    required Color color,
    required String title,
    required String text,
  }) {
    return Card(
      color: color.withOpacity(0.06),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.12),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    text,
                    style: TextStyle(color: Colors.grey.shade700, height: 1.35),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget selectedToolBody() {
    switch (selectedTool) {
      case 'RENT_DELAY':
        return rentDelayTool();
      case 'RISK_SCORE':
        return riskScoreTool();
      case 'TENANT_360':
      default:
        return tenant360Tool();
    }
  }

  Widget assistantRestrictedBody() {
    return RefreshIndicator(
      onRefresh: refreshPage,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF4C1D95),
                  Color(0xFF6750A4),
                  Color(0xFF8B7DD8),
                ],
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
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 31,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.support_agent, color: primary, size: 31),
                ),
                SizedBox(height: 18),
                Text(
                  'AI Replies are in Tickets',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 27,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Assistants use AI directly inside Ticket Details where conversation context is available.',
                  style: TextStyle(color: Colors.white70, height: 1.35),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 31,
                    backgroundColor: primary.withOpacity(0.12),
                    child: const Icon(Icons.auto_fix_high, color: primary),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Assistant AI workspace',
                    style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tenant intelligence tools are restricted to admins, owners and agents. For assistant workflows, open a ticket and use “Suggest Reply with AI”.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade700, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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
      onRefresh: refreshPage,
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
                    'Could not load AI assistant',
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
                    onPressed: refreshPage,
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

  Widget bodyContent() {
    if (roleLoading) return loadingBody();

    if (isAssistant) return assistantRestrictedBody();

    if (error.isNotEmpty && tenants.isEmpty && !loadingTenants) {
      return errorBody();
    }

    return RefreshIndicator(
      onRefresh: refreshPage,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          heroHeader(),
          const SizedBox(height: 16),
          errorCard(),
          if (error.isNotEmpty) const SizedBox(height: 12),
          toolCards(),
          const SizedBox(height: 16),
          if (!hasTenants && !loadingTenants)
            noTenantsCard()
          else
            selectedToolBody(),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: softBg,
      appBar: AppBar(
        title: const Text(
          'AI Assistant',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: refreshing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            onPressed: refreshing ? null : refreshPage,
          ),
        ],
      ),
      body: bodyContent(),
    );
  }
}

class _ConfirmMessageSheet extends StatelessWidget {
  final String tenantName;
  final String message;

  const _ConfirmMessageSheet({required this.tenantName, required this.message});

  static const primary = Color(0xFF6750A4);
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
              _dragHandle(),
              const SizedBox(height: 22),
              CircleAvatar(
                radius: 32,
                backgroundColor: primary.withOpacity(0.12),
                child: const Icon(Icons.send, color: primary, size: 34),
              ),
              const SizedBox(height: 16),
              const Text(
                'Send AI Message?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Send this AI suggested message to $tenantName?',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700, height: 1.45),
              ),
              const SizedBox(height: 14),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: SelectableText(message),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context, true),
                  icon: const Icon(Icons.send),
                  label: const Text('Send Message'),
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

class _Tenant360Sheet extends StatelessWidget {
  final Map<String, dynamic> result;
  final String tenantName;
  final String Function(dynamic value) formatDate;
  final Color Function(String? value) riskColor;
  final IconData Function(String? value) riskIcon;
  final Future<void> Function(String text) onCopyMessage;
  final Future<void> Function(String message) onSendMessage;

  const _Tenant360Sheet({
    required this.result,
    required this.tenantName,
    required this.formatDate,
    required this.riskColor,
    required this.riskIcon,
    required this.onCopyMessage,
    required this.onSendMessage,
  });

  static const primary = Color(0xFF6750A4);
  static const softBg = Color(0xFFF8F5FF);

  @override
  Widget build(BuildContext context) {
    final tenant = result['tenant'] ?? {};
    final lease = result['lease'];
    final financials = result['financials'] ?? {};
    final maintenance = result['maintenance'] ?? {};
    final ai = result['ai'] ?? {};
    final invoices = result['invoices'];

    final riskLevel = ai['riskLevel']?.toString() ?? 'UNKNOWN';
    final riskScore = ai['riskScore']?.toString() ?? '0';
    final color = riskColor(riskLevel);
    final suggestedMessage = ai['suggestedMessage']?.toString() ?? '';

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
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
                _dragHandle(),
                const SizedBox(height: 20),
                CircleAvatar(
                  radius: 38,
                  backgroundColor: color.withOpacity(0.12),
                  child: Icon(riskIcon(riskLevel), color: color, size: 38),
                ),
                const SizedBox(height: 14),
                Text(
                  tenant['name']?.toString() ?? tenantName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  tenant['email']?.toString() ?? '',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 14),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(
                      avatar: Icon(riskIcon(riskLevel), color: color, size: 18),
                      label: Text(riskLevel),
                      backgroundColor: color.withOpacity(0.12),
                      labelStyle: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                      side: BorderSide.none,
                    ),
                    Chip(
                      avatar: Icon(
                        Icons.health_and_safety,
                        color: color,
                        size: 18,
                      ),
                      label: Text('$riskScore / 100'),
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
                _scoreCard(
                  title: ai['healthLabel']?.toString() ?? 'Tenant health',
                  value: double.tryParse(riskScore) ?? 0,
                  color: color,
                  icon: Icons.health_and_safety,
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Text(
                      ai['managementSummary']?.toString() ??
                          'No management summary available.',
                      style: const TextStyle(height: 1.45),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _metricsGrid(financials, maintenance),
                const SizedBox(height: 12),
                if (lease != null) _leaseCard(lease),
                if (lease != null) const SizedBox(height: 12),
                _listCard(
                  title: 'Risk Factors',
                  icon: Icons.report_problem,
                  color: Colors.red,
                  items: ai['riskFactors'],
                ),
                _listCard(
                  title: 'Positive Signals',
                  icon: Icons.check_circle,
                  color: Colors.green,
                  items: ai['positiveSignals'],
                ),
                _listCard(
                  title: 'Next Best Actions',
                  icon: Icons.task_alt,
                  color: primary,
                  items: ai['nextBestActions'],
                ),
                if (suggestedMessage.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Suggested Tenant Message',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          SelectableText(suggestedMessage),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () =>
                                      onCopyMessage(suggestedMessage),
                                  icon: const Icon(Icons.copy),
                                  label: const Text('Copy'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    onSendMessage(suggestedMessage);
                                  },
                                  icon: const Icon(Icons.send),
                                  label: const Text('Send'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                if (invoices is List && invoices.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _recentInvoicesCard(invoices),
                ],
                const SizedBox(height: 10),
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

  Widget _scoreCard({
    required String title,
    required double value,
    required IconData icon,
    required Color color,
  }) {
    final safeValue = value.clamp(0, 100).toDouble();

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
                  '${safeValue.round()}%',
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
                value: safeValue / 100,
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

  Widget _metricsGrid(dynamic financials, dynamic maintenance) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.22,
      children: [
        _metric(
          title: 'Unpaid',
          value: financials['totalUnpaid']?.toString() ?? '0',
          icon: Icons.warning_amber,
          color: Colors.orange,
        ),
        _metric(
          title: 'Collection',
          value: '${financials['collectionRate'] ?? 0}%',
          icon: Icons.payments,
          color: Colors.green,
        ),
        _metric(
          title: 'Open Tickets',
          value: maintenance['openTickets']?.toString() ?? '0',
          icon: Icons.construction,
          color: Colors.red,
        ),
        _metric(
          title: 'Overdue',
          value: financials['overdueInvoices']?.toString() ?? '0',
          icon: Icons.receipt_long,
          color: primary,
        ),
      ],
    );
  }

  Widget _metric({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.12),
              child: Icon(icon, color: color),
            ),
            const Spacer(),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            Text(
              title,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _leaseCard(dynamic lease) {
    final unit = lease['unit'];
    final property = unit?['property'];

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: primary.withOpacity(0.12),
          child: const Icon(Icons.description, color: primary),
        ),
        title: const Text(
          'Lease Snapshot',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${property?['title'] ?? property?['name'] ?? 'Property'} • ${unit?['title'] ?? unit?['number'] ?? 'Unit'}\n'
          'Status: ${lease['status']} • Ends: ${formatDate(lease['endDate'])}\n'
          'Days left: ${lease['daysUntilEnd'] ?? '—'}',
        ),
        isThreeLine: true,
      ),
    );
  }

  Widget _listCard({
    required String title,
    required IconData icon,
    required Color color,
    required dynamic items,
  }) {
    final list = items is List ? items : [];

    if (list.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
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
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ...list.map(
                (item) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.chevron_right),
                  title: Text(item.toString()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _recentInvoicesCard(List invoices) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Invoice Signals',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...invoices.take(5).map((invoice) {
              final remaining = invoice['remainingAmount'] ?? 0;
              final overdue = invoice['isOverdue'] == true;

              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  overdue ? Icons.warning_amber : Icons.receipt_long,
                  color: overdue ? Colors.red : primary,
                ),
                title: Text('Invoice: ${invoice['amount']}'),
                subtitle: Text(
                  'Remaining: $remaining • Due: ${formatDate(invoice['dueDate'])}',
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _AiResultSheet extends StatelessWidget {
  final String title;
  final Map<String, dynamic> result;
  final String badgeKey;
  final String itemsKey;
  final String actionsKey;
  final Color Function(String? value) riskColor;
  final IconData Function(String? value) riskIcon;
  final Future<void> Function(String text) onCopy;

  const _AiResultSheet({
    required this.title,
    required this.result,
    required this.badgeKey,
    required this.itemsKey,
    required this.actionsKey,
    required this.riskColor,
    required this.riskIcon,
    required this.onCopy,
  });

  static const primary = Color(0xFF6750A4);
  static const softBg = Color(0xFFF8F5FF);

  @override
  Widget build(BuildContext context) {
    final badge = result[badgeKey]?.toString() ?? 'AI';
    final color = riskColor(badge);

    final score =
        result['riskScore'] ??
        result['score'] ??
        result['probability'] ??
        result['delayProbability'] ??
        0;

    final summary =
        result['summary'] ??
        result['message'] ??
        result['prediction'] ??
        result['managementSummary'] ??
        '';

    final items = result[itemsKey] is List ? result[itemsKey] as List : [];
    final actions = result[actionsKey] is List
        ? result[actionsKey] as List
        : [];

    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.50,
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
                _dragHandle(),
                const SizedBox(height: 20),
                CircleAvatar(
                  radius: 36,
                  backgroundColor: color.withOpacity(0.12),
                  child: Icon(riskIcon(badge), color: color, size: 36),
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
                const SizedBox(height: 12),
                Chip(
                  avatar: Icon(riskIcon(badge), color: color, size: 18),
                  label: Text(badge),
                  backgroundColor: color.withOpacity(0.12),
                  labelStyle: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                  side: BorderSide.none,
                ),
                const SizedBox(height: 18),
                Card(
                  color: color.withOpacity(0.07),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        Text(
                          '$score / 100',
                          style: TextStyle(
                            color: color,
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (summary.toString().trim().isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            summary.toString(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey.shade800,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (items.isNotEmpty)
                  _listCard(
                    title: 'AI Signals',
                    icon: Icons.insights,
                    color: primary,
                    items: items,
                  ),
                if (actions.isNotEmpty)
                  _listCard(
                    title: 'Recommended Actions',
                    icon: Icons.task_alt,
                    color: Colors.green,
                    items: actions,
                  ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => onCopy(result.toString()),
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy Result'),
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

  Widget _listCard({
    required String title,
    required IconData icon,
    required Color color,
    required List items,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
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
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ...items.map(
                (item) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.chevron_right),
                  title: Text(item.toString()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _dragHandle() {
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
