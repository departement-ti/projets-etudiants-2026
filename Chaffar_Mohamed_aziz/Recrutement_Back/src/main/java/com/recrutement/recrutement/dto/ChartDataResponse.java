package com.recrutement.recrutement.dto;

import java.util.List;

public class ChartDataResponse {
    private String title;
    private List<String> labels;
    private List<Long> values;

    public ChartDataResponse() {
    }

    public ChartDataResponse(String title, List<String> labels, List<Long> values) {
        this.title = title;
        this.labels = labels;
        this.values = values;
    }

    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }
    public List<String> getLabels() { return labels; }
    public void setLabels(List<String> labels) { this.labels = labels; }
    public List<Long> getValues() { return values; }
    public void setValues(List<Long> values) { this.values = values; }
}
