package com.recrutement.recrutement.repositories;

import com.recrutement.recrutement.entities.AiAnswer;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface AiAnswerRepository extends JpaRepository<AiAnswer, Long> {
    List<AiAnswer> findByAiTest_IdOrderByIdAsc(Long testId);

    List<AiAnswer> findByAiTestResult_IdOrderByIdAsc(Long resultId);

    AiAnswer findByAiTestResult_IdAndQuestion_Id(Long resultId, Long questionId);

    @Modifying(flushAutomatically = true, clearAutomatically = true)
    @Query("delete from AiAnswer a where a.aiTest.id in :testIds")
    void deleteByAiTestIds(@Param("testIds") List<Long> testIds);
}
