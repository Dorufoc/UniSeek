package com.uniseek.service;

import com.uniseek.common.PageResult;
import com.uniseek.dto.TaskRequest;
import com.uniseek.dto.TaskSearchRequest;
import com.uniseek.dto.TaskVO;
import com.uniseek.entity.Task;

/**
 * 职位任务服务接口
 */
public interface TaskService {

    /**
     * 发布职位
     * <p>
     * 前置条件：
     * <ul>
     *   <li>企业已认证（audit_status = 1）</li>
     * </ul>
     * 创建后状态为 0（待审核），remaining_quota = total_quota
     *
     * @param enterpriseId 当前企业 ID
     * @param request      职位请求
     * @return 创建的职位
     */
    Task create(Long enterpriseId, TaskRequest request);

    /**
     * 多条件组合分页搜索职位
     *
     * @param req 搜索条件
     * @return 分页结果
     */
    PageResult<TaskVO> search(TaskSearchRequest req);

    /**
     * 查询职位详情
     *
     * @param id     职位 ID
     * @param userId 当前用户 ID（用于判断是否已投递）
     * @return 职位详情 VO
     */
    TaskVO getDetail(Long id, Long userId);

    /**
     * 更新职位信息
     * <p>
     * 仅限待审核（0）/ 已下架（4）状态的职位可更新
     *
     * @param enterpriseId 当前企业 ID
     * @param id           职位 ID
     * @param request      更新请求
     * @return 更新后的职位
     */
    Task update(Long enterpriseId, Long id, TaskRequest request);

    /**
     * 修改职位状态
     * <p>
     * HR 只能下架自己的职位（→ 4），
     * Admin 可审核通过（→ 1）或下架（→ 4）
     *
     * @param userId       当前用户 ID
     * @param userRole     当前用户角色
     * @param id           职位 ID
     * @param targetStatus 目标状态
     */
    void updateStatus(Long userId, Integer userRole, Long id, Integer targetStatus);

    /**
     * 查询本企业职位列表
     *
     * @param enterpriseId 企业 ID
     * @return 职位列表
     */
    PageResult<TaskVO> getEnterpriseTasks(Long enterpriseId);
}
