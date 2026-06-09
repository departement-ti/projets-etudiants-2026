package com.tmazzacademy.tmazzacademy.service;

import com.tmazzacademy.tmazzacademy.model.Admin;
import com.tmazzacademy.tmazzacademy.repository.AdminRepository;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class AdminService {

    private final AdminRepository adminRepository;

    public AdminService(AdminRepository adminRepository) {
        this.adminRepository = adminRepository;
    }

    // CREATE
    public Admin addAdmin(Admin admin) {
        return adminRepository.save(admin);
    }

    // GET ALL
    public List<Admin> getAllAdmins() {
        return adminRepository.findAll();
    }

    // GET BY ID
    public Admin getAdminById(Long id) {
        return adminRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Admin not found with id: " + id));
    }

    // UPDATE
    public Admin updateAdmin(Long id, Admin updatedAdmin) {
        Admin admin = getAdminById(id);

        admin.setName(updatedAdmin.getName());
        admin.setLastname(updatedAdmin.getLastname());
        admin.setEmail(updatedAdmin.getEmail());
        admin.setPassword(updatedAdmin.getPassword());
        admin.setTel(updatedAdmin.getTel());
        admin.setRole(updatedAdmin.getRole());

        return adminRepository.save(admin);
    }

    // DELETE
    public void deleteAdmin(Long id) {
        adminRepository.deleteById(id);
    }
}