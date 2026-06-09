package com.tmazzacademy.tmazzacademy.model;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;

@Entity
public class PollOption {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String optionText;

    private int votes = 0;

    @ManyToOne
    @JoinColumn(name = "message_id")
    @JsonIgnore
    private ChatMessage message;

    public PollOption() {}

    public Long getId() { return id; }

    public String getOptionText() { return optionText; }
    public void setOptionText(String optionText) { this.optionText = optionText; }

    public int getVotes() { return votes; }
    public void setVotes(int votes) { this.votes = votes; }

    public ChatMessage getMessage() { return message; }
    public void setMessage(ChatMessage message) { this.message = message; }
}