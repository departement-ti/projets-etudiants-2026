package com.recrutement.recrutement.controller;

import com.recrutement.recrutement.dto.AdminActivityResponse;
import com.recrutement.recrutement.service.AdminStatisticsService;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/admin/activity")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class AdminActivityController {
    private final AdminStatisticsService adminStatisticsService;

    @GetMapping("/recent")
    public ResponseEntity<List<AdminActivityResponse>> getRecentActivity() {
        return ResponseEntity.ok(adminStatisticsService.getRecentActivity());
    }
}
