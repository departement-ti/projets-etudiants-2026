package com.recrutement.recrutement.controller;

import com.recrutement.recrutement.dto.ServiceHealthResponse;
import com.recrutement.recrutement.service.AdminStatisticsService;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/admin/system-health")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class AdminSystemHealthController {
    private final AdminStatisticsService adminStatisticsService;

    @GetMapping
    public ResponseEntity<List<ServiceHealthResponse>> getSystemHealth() {
        return ResponseEntity.ok(adminStatisticsService.getSystemHealth());
    }
}
