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

import java.time.LocalDateTime;
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

    /**
     * 职位大类需求占比（按顶级分类分组，统计招聘中职位数）
     *
     * @param startTime 开始时间（可为 null）
     * @param endTime   结束时间（可为 null）
     */
    @Select("<script>" +
            "SELECT cat.name AS categoryName, sub.cnt AS count " +
            "FROM (" +
            "  SELECT COALESCE(p.id, c.id) AS categoryId, COUNT(*) AS cnt " +
            "  FROM task t " +
            "  JOIN category c ON t.category_id = c.id " +
            "  LEFT JOIN category p ON c.parent_id = p.id " +
            "  WHERE t.status = 1 " +
            "  <if test='startTime != null'>AND t.create_time &gt;= #{startTime}</if>" +
            "  <if test='endTime != null'>AND t.create_time &lt;= #{endTime}</if>" +
            "  GROUP BY categoryId" +
            ") sub " +
            "JOIN category cat ON sub.categoryId = cat.id " +
            "ORDER BY sub.cnt DESC" +
            "</script>")
    List<Map<String, Object>> selectCategoryDistribution(@Param("startTime") LocalDateTime startTime,
                                                          @Param("endTime") LocalDateTime endTime);

    /**
     * 人才流向数据
     *
     * @param startTime 投递开始时间（可为 null）
     * @param endTime   投递结束时间（可为 null）
     */
    @Select("<script>" +
            "SELECT " +
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
            "AND LENGTH(rna.id_card) &gt;= 6 " +
            "<if test='startTime != null'>AND ta.create_time &gt;= #{startTime}</if>" +
            "<if test='endTime != null'>AND ta.create_time &lt;= #{endTime}</if>" +
            "GROUP BY fromCode, e.region_id " +
            "ORDER BY flowCount DESC" +
            "</script>")
    List<Map<String, Object>> selectTalentFlow(@Param("startTime") LocalDateTime startTime,
                                                @Param("endTime") LocalDateTime endTime);

    /**
     * 热门岗位 TOP10（按投递量倒序）
     *
     * @param startTime 投递开始时间（可为 null）
     * @param endTime   投递结束时间（可为 null）
     */
    @Select("<script>" +
            "SELECT t.id, t.title, e.company_name AS companyName, COUNT(ta.id) AS applicationCount " +
            "FROM task t " +
            "JOIN enterprise e ON t.enterprise_id = e.id " +
            "LEFT JOIN task_application ta ON ta.task_id = t.id " +
            "WHERE t.status = 1 " +
            "<if test='startTime != null'>AND ta.create_time &gt;= #{startTime}</if>" +
            "<if test='endTime != null'>AND ta.create_time &lt;= #{endTime}</if>" +
            "GROUP BY t.id " +
            "ORDER BY applicationCount DESC LIMIT 10" +
            "</script>")
    List<Map<String, Object>> selectHotTasks(@Param("startTime") LocalDateTime startTime,
                                              @Param("endTime") LocalDateTime endTime);

    /**
     * 管理后台分页查询职位列表（LEFT JOIN enterprise 获取企业名称）
     *
     * @param page    分页对象
     * @param status  状态筛选（可为 null）
     * @param keyword 关键字搜索职位标题（可为 null）
     * @return 职位分页结果（含 enterpriseName）
     */
    IPage<Task> selectAdminTaskPage(Page<Task> page,
                                    @Param("status") Integer status,
                                    @Param("keyword") String keyword,
                                    @Param("rejected") Boolean rejected);

    /**
     * 查询指定企业的已发布职位（status = 1）
     *
     * @param enterpriseId 企业 ID
     * @return 职位列表
     */
    List<TaskVO> selectPublishedEnterpriseTasks(@Param("enterpriseId") Long enterpriseId);

    /**
     * 获取所有已启用的职位标签（去重）
     *
     * @return 所有不重复的标签名称
     */
    List<String> selectAllTags();
}
