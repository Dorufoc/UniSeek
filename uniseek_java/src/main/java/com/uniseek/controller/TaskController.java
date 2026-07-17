package com.uniseek.controller;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.uniseek.common.ApiResult;
import com.uniseek.common.PageResult;
import com.uniseek.operationlog.annotation.OperationLog;
import com.uniseek.common.exception.BusinessException;
import com.uniseek.common.util.UserContext;
import com.uniseek.dao.EnterpriseMapper;
import com.uniseek.dto.TaskRequest;
import com.uniseek.dto.TaskSearchRequest;
import com.uniseek.dto.TaskVO;
import com.uniseek.entity.Enterprise;
import com.uniseek.entity.Task;
import com.uniseek.service.TaskService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import javax.validation.Valid;
import java.util.List;

/**
 * 职位任务控制器
 */
@RestController
@RequestMapping("/api")
public class TaskController {

    @Autowired
    private TaskService taskService;

    @Autowired
    private EnterpriseMapper enterpriseMapper;

    /**
     * 职位搜索
     * GET /api/tasks（无需鉴权）
     *
     * @param req 搜索条件
     * @return 分页结果
     */
    @GetMapping("/tasks")
    public ApiResult<PageResult<TaskVO>> search(TaskSearchRequest req) {
        PageResult<TaskVO> result = taskService.search(req);
        return ApiResult.success(result);
    }

    /**
     * 职位详情
     * GET /api/tasks/{id}（需要鉴权）
     *
     * @param id 职位 ID
     * @return 职位详情
     */
    @GetMapping("/tasks/{id}")
    public ApiResult<TaskVO> getDetail(@PathVariable Long id) {
        Long userId = UserContext.getUserId();
        TaskVO vo = taskService.getDetail(id, userId);
        return ApiResult.success(vo);
    }

    /**
     * 发布职位
     * POST /api/tasks（需要鉴权）
     *
     * @param request 职位请求
     * @return 创建的职位
     */
    @PostMapping("/tasks")
    @OperationLog(operationType = "TASK_PUBLISH", targetType = "TASK")
    public ApiResult<Task> create(@Valid @RequestBody TaskRequest request) {
        Long userId = UserContext.getUserId();
        Long enterpriseId = getEnterpriseIdByUserId(userId);
        Task task = taskService.create(enterpriseId, request);
        return ApiResult.success("发布成功，等待审核", task);
    }

    /**
     * 更新职位
     * PUT /api/tasks/{id}（需要鉴权）
     *
     * @param id      职位 ID
     * @param request 更新请求
     * @return 更新后的职位
     */
    @PutMapping("/tasks/{id}")
    @OperationLog(operationType = "TASK_PUBLISH", targetType = "TASK", targetIdExpression = "#id")
    public ApiResult<Task> update(@PathVariable Long id,
                                   @Valid @RequestBody TaskRequest request) {
        Long userId = UserContext.getUserId();
        Long enterpriseId = getEnterpriseIdByUserId(userId);
        Task task = taskService.update(enterpriseId, id, request);
        return ApiResult.success("更新成功", task);
    }

    /**
     * 修改职位状态
     * PUT /api/tasks/{id}/status（需要鉴权）
     *
     * @param id           职位 ID
     * @param targetStatus 目标状态
     * @return 操作结果
     */
    @PutMapping("/tasks/{id}/status")
    @OperationLog(operationType = "TASK_OFFLINE", targetType = "TASK", targetIdExpression = "#id")
    public ApiResult<Void> updateStatus(@PathVariable Long id,
                                         @RequestParam Integer targetStatus) {
        Long userId = UserContext.getUserId();
        Integer userRole = UserContext.getRole();
        taskService.updateStatus(userId, userRole, id, targetStatus);
        return ApiResult.success("状态更新成功", null);
    }

    /**
     * 查询指定企业的已发布职位（供求职者查看公司详情）
     * GET /api/enterprise/{enterpriseId}/tasks
     */
    @GetMapping("/enterprise/{enterpriseId}/tasks")
    public ApiResult<List<TaskVO>> getPublishedEnterpriseTasks(@PathVariable Long enterpriseId) {
        List<TaskVO> list = taskService.getPublishedEnterpriseTasks(enterpriseId);
        return ApiResult.success(list);
    }

    /**
     * 获取所有职位标签（去重）
     * GET /api/tasks/tags/all（无需鉴权）
     */
    @GetMapping("/tasks/tags/all")
    public ApiResult<List<String>> getAllTags() {
        List<String> tags = taskService.getAllTags();
        return ApiResult.success(tags);
    }

    /**
     * 本企业职位列表
     * GET /api/enterprise/tasks（需要鉴权）
     *
     * @return 职位列表
     */
    @GetMapping("/enterprise/tasks")
    @OperationLog(operationType = "TASK_PUBLISH", targetType = "TASK")
    public ApiResult<PageResult<TaskVO>> getEnterpriseTasks() {
        Long userId = UserContext.getUserId();
        Long enterpriseId = getEnterpriseIdByUserId(userId);
        PageResult<TaskVO> result = taskService.getEnterpriseTasks(enterpriseId);
        return ApiResult.success(result);
    }

    /**
     * 重新提交审核（HR 根据驳回原因修改后重新申请）
     * PUT /api/tasks/{id}/resubmit（需要鉴权）
     *
     * @param id 职位 ID
     * @return 操作结果
     */
    @PutMapping("/tasks/{id}/resubmit")
    @OperationLog(operationType = "TASK_RESUBMIT", targetType = "TASK", targetIdExpression = "#id")
    public ApiResult<Void> resubmit(@PathVariable Long id) {
        Long userId = UserContext.getUserId();
        taskService.resubmit(userId, id);
        return ApiResult.success("已重新提交审核", null);
    }

    /**
     * 根据用户 ID 获取企业 ID
     *
     * @param userId 当前用户 ID
     * @return 企业 ID
     */
    private Long getEnterpriseIdByUserId(Long userId) {
        Enterprise enterprise = enterpriseMapper.selectOne(
                new LambdaQueryWrapper<Enterprise>()
                        .eq(Enterprise::getUserId, userId));
        if (enterprise == null) {
            throw new BusinessException("未找到企业信息，请先提交企业资质认证");
        }
        return enterprise.getId();
    }
}
