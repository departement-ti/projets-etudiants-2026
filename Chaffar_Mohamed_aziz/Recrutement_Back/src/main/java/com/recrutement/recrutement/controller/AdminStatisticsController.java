package com.recrutement.recrutement.controller;

import com.recrutement.recrutement.dto.AdminOverviewStatsResponse;
import com.recrutement.recrutement.dto.AiInsightResponse;
import com.recrutement.recrutement.dto.AiTestStatsResponse;
import com.recrutement.recrutement.dto.ChartDataResponse;
import com.recrutement.recrutement.dto.ServiceHealthResponse;
import com.recrutement.recrutement.dto.TopSkillResponse;
import com.recrutement.recrutement.service.AdminStatisticsService;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/admin/statistics")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class AdminStatisticsController {
    private final AdminStatisticsService adminStatisticsService;

    @GetMapping("/overview")
    public ResponseEntity<AdminOverviewStatsResponse> getOverview() {
        return ResponseEntity.ok(adminStatisticsService.getOverview());
    }

    @GetMapping("/applications-by-status")
    public ResponseEntity<ChartDataResponse> getApplicationsByStatus() {
        return ResponseEntity.ok(adminStatisticsService.getApplicationsByStatus());
    }

    @GetMapping("/offers-by-month")
    public ResponseEntity<ChartDataResponse> getOffersByMonth() {
        return ResponseEntity.ok(adminStatisticsService.getOffersByMonth());
    }

    @GetMapping("/applications-by-month")
    public ResponseEntity<ChartDataResponse> getApplicationsByMonth() {
        return ResponseEntity.ok(adminStatisticsService.getApplicationsByMonth());
    }

    @GetMapping("/top-skills")
    public ResponseEntity<List<TopSkillResponse>> getTopSkills() {
        return ResponseEntity.ok(adminStatisticsService.getTopSkills());
    }

    @GetMapping("/ai-tests")
    public ResponseEntity<AiTestStatsResponse> getAiTests() {
        return ResponseEntity.ok(adminStatisticsService.getAiTestStats());
    }

    @GetMapping("/insights")
    public ResponseEntity<List<AiInsightResponse>> getInsights() {
        return ResponseEntity.ok(adminStatisticsService.getAiInsights());
    }

    @GetMapping("/system-health")
    public ResponseEntity<List<ServiceHealthResponse>> getSystemHealth() {
        return ResponseEntity.ok(adminStatisticsService.getSystemHealth());
    }
}
