package com.rayhan.erp.controller;

import com.rayhan.erp.service.DashboardService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/dashboard")
public class DashboardController {

    @Autowired
    private DashboardService dashboardService;

    @GetMapping
    @PreAuthorize("hasRole('ROLE_PDG')")
    public Map<String, Object> getDashboard() {
        return dashboardService.getDashboard();
    }
}
