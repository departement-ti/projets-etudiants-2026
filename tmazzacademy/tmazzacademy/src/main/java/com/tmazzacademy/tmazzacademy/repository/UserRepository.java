package com.tmazzacademy.tmazzacademy.repository;

import org.springframework.data.jpa.repository.JpaRepository;

import com.tmazzacademy.tmazzacademy.model.User;

public interface UserRepository extends JpaRepository<User, Long> {
    User findByEmail(String email);
    boolean existsByEmail(String email);
}