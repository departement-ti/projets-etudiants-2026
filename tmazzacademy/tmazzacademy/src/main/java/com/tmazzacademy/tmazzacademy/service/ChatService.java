package com.tmazzacademy.tmazzacademy.service;

import com.tmazzacademy.tmazzacademy.model.ChatMessage;
import com.tmazzacademy.tmazzacademy.model.PollOption;
import com.tmazzacademy.tmazzacademy.model.PollVote;
import com.tmazzacademy.tmazzacademy.repository.ChatMessageRepository;
import com.tmazzacademy.tmazzacademy.repository.PollOptionRepository;
import com.tmazzacademy.tmazzacademy.repository.PollVoteRepository;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.File;
import java.util.List;
import java.util.UUID;

@Service
public class ChatService {

    private final ChatMessageRepository messageRepository;
    private final PollOptionRepository optionRepository;
    private final PollVoteRepository voteRepository;

    public ChatService(
            ChatMessageRepository messageRepository,
            PollOptionRepository optionRepository,
            PollVoteRepository voteRepository
    ) {
        this.messageRepository = messageRepository;
        this.optionRepository = optionRepository;
        this.voteRepository = voteRepository;
    }

    public List<ChatMessage> getMessages() {
        return messageRepository.findAllByOrderByCreatedAtAsc();
    }

    public ChatMessage sendText(
            String content,
            Long senderId,
            String senderName,
            String senderRole
    ) {
        ChatMessage message = new ChatMessage();

        message.setContent(content);
        message.setType("TEXT");
        message.setSenderId(senderId);
        message.setSenderName(senderName);
        message.setSenderRole(senderRole);

        return messageRepository.save(message);
    }

    public ChatMessage sendImage(
            MultipartFile image,
            Long senderId,
            String senderName,
            String senderRole
    ) {
        try {
            String uploadDir =
                    System.getProperty("user.dir")
                            + File.separator
                            + "uploads"
                            + File.separator
                            + "chat"
                            + File.separator;

            new File(uploadDir).mkdirs();

            String fileName =
                    UUID.randomUUID() + "_" + image.getOriginalFilename();

            File file = new File(uploadDir + fileName);

            image.transferTo(file);

            ChatMessage message = new ChatMessage();

            message.setType("IMAGE");
            message.setImagePath("uploads/chat/" + fileName);
            message.setSenderId(senderId);
            message.setSenderName(senderName);
            message.setSenderRole(senderRole);

            return messageRepository.save(message);

        } catch (Exception e) {
            throw new RuntimeException("Error uploading chat image");
        }
    }

    public ChatMessage createPoll(
            String question,
            List<String> options,
            Long senderId,
            String senderName,
            String senderRole
    ) {
        ChatMessage message = new ChatMessage();

        message.setType("POLL");
        message.setContent(question);
        message.setSenderId(senderId);
        message.setSenderName(senderName);
        message.setSenderRole(senderRole);

        ChatMessage savedMessage = messageRepository.save(message);

        for (String opt : options) {
            if (opt != null && !opt.trim().isEmpty()) {
                PollOption option = new PollOption();
                option.setOptionText(opt);
                option.setVotes(0);
                option.setMessage(savedMessage);
                optionRepository.save(option);
            }
        }

        return messageRepository.findById(savedMessage.getId())
                .orElseThrow(() -> new RuntimeException("Message not found"));
    }

    public ChatMessage vote(Long messageId, Long optionId, Long userId) {

        ChatMessage message = messageRepository.findById(messageId)
                .orElseThrow(() -> new RuntimeException("Poll not found"));

        PollOption option = optionRepository.findById(optionId)
                .orElseThrow(() -> new RuntimeException("Option not found"));

        if (voteRepository.existsByUserIdAndMessage(userId, message)) {
            throw new RuntimeException("You already voted");
        }

        option.setVotes(option.getVotes() + 1);
        optionRepository.save(option);

        PollVote vote = new PollVote();
        vote.setUserId(userId);
        vote.setMessage(message);
        vote.setOption(option);

        voteRepository.save(vote);

        return messageRepository.findById(messageId)
                .orElseThrow(() -> new RuntimeException("Poll not found"));
    }
}