package com.rayhan.erp.service;

import com.rayhan.erp.model.ReferenceSequence;
import com.rayhan.erp.repository.ReferenceSequenceRepository;
import jakarta.annotation.PostConstruct;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;

@Service
public class SequenceService {

    @Autowired
    private ReferenceSequenceRepository repository;

    @PostConstruct
    @Transactional
    public void init() {
        List.of("CC", "BL", "BC", "BR", "OF").forEach(type -> {
            if (!repository.existsById(type)) {
                repository.save(new ReferenceSequence(type, 0));
            }
        });
    }

    public synchronized long getNextValue(String type) {
        ReferenceSequence seq = repository.findById(type)
            .orElseGet(() -> repository.save(new ReferenceSequence(type, 0)));
        long next = seq.getCurrentValue() + 1;
        seq.setCurrentValue(next);
        repository.save(seq);
        return next;
    }

    public synchronized String generateRef(String prefix) {
        long num = getNextValue(prefix);
        return prefix + "-" + LocalDate.now().getYear() + "-" + String.format("%03d", num);
    }
}
