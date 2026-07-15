package com.uniseek.dao;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.uniseek.dto.TaskSearchRequest;
import com.uniseek.dto.TaskVO;
import com.uniseek.entity.Task;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

import java.util.List;
import java.util.Map;

/**
 * 职位任务 Mapper
 */
@Mapper
public interface TaskMapper extends BaseMapper<Task> {

    /**
     * 分页条件搜索职位
     *
     * @param page  MyBatis-Plus 分页对象
     * @param req   搜索条件
     * @return 分页结果
     */
    IPage<TaskVO> selectPageByCondition(Page<TaskVO> page, @Param("req") TaskSearchRequest req);

    /**
     * 查询职位详情（含是否已投递标记）
     *
     * @param id     职位 ID
     * @param userId 当前用户 ID
     * @return 职位详情 VO
     */
    TaskVO selectDetailById(@Param("id") Long id, @Param("userId") Long userId);

    /**
     * 查询本企业所有职位
     *
     * @param enterpriseId 企业 ID
     * @return 职位列表
     */
    List<TaskVO> selectEnterpriseTasks(@Param("enterpriseId") Long enterpriseId);

<<<<<<< HEAD
    @Select("SELECT c.name AS industry, COUNT(t.id) AS count FROM task t JOIN category c ON t.category_id = c.id WHERE t.status = 1 GROUP BY t.category_id ORDER BY count DESC")
    List<Map<String, Object>> selectIndustryDistribution();

    @Select("SELECT " +
            "SUBSTRING(rna.id_card, 1, 6) AS fromCode, " +
            "e.region_id AS toCode, " +
            "COUNT(*) AS flowCount " +
            "FROM task_application ta " +
            "JOIN task t ON ta.task_id = t.id " +
            "JOIN enterprise e ON t.enterprise_id = e.id " +
            "JOIN user u ON ta.applicant_id = u.id " +
            "JOIN real_name_auth rna ON u.id = rna.user_id " +
            "WHERE e.region_id IS NOT NULL " +
            "AND rna.id_card IS NOT NULL " +
            "AND LENGTH(rna.id_card) >= 6 " +
            "GROUP BY fromCode, e.region_id " +
            "ORDER BY flowCount DESC")
    List<Map<String, Object>> selectTalentFlow();

    @Select("SELECT t.id, t.title, e.company_name AS companyName, COUNT(ta.id) AS applicationCount FROM task t JOIN enterprise e ON t.enterprise_id = e.id LEFT JOIN task_application ta ON ta.task_id = t.id WHERE t.status = 1 GROUP BY t.id ORDER BY applicationCount DESC LIMIT 10")
    List<Map<String, Object>> selectHotTasks();

    /**
     * 查询指定企业的已发布职位（status = 1）
     *
     * @param enterpriseId 企业 ID
     * @return 职位列表
     */
    List<TaskVO> selectPublishedEnterpriseTasks(@Param("enterpriseId") Long enterpriseId);
}
