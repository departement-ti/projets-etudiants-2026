package com.tmazzacademy.tmazzacademy.repository;

import com.tmazzacademy.tmazzacademy.model.PollOption;
import org.springframework.data.jpa.repository.JpaRepository;

public interface PollOptionRepository extends JpaRepository<PollOption, Long> {
}