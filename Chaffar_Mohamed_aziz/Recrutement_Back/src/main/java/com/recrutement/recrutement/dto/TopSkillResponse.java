package com.recrutement.recrutement.dto;

public class TopSkillResponse {
    private String name;
    private long count;

    public TopSkillResponse() {
    }

    public TopSkillResponse(String name, long count) {
        this.name = name;
        this.count = count;
    }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    public long getCount() { return count; }
    public void setCount(long count) { this.count = count; }
}
