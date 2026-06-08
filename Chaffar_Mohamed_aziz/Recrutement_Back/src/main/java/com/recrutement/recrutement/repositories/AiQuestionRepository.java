package com.recrutement.recrutement.repositories;

import com.recrutement.recrutement.entities.AiQuestion;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface AiQuestionRepository extends JpaRepository<AiQuestion, Long> {
    List<AiQuestion> findByAiTest_IdOrderByIdAsc(Long testId);

    List<AiQuestion> findByAiTest_IdOrderByOrderIndexAscIdAsc(Long testId);

    @Modifying(flushAutomatically = true, clearAutomatically = true)
    @Query("delete from AiQuestion q where q.aiTest.id in :testIds")
    void deleteByAiTestIds(@Param("testIds") List<Long> testIds);
}
