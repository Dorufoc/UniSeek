package com.uniseek.controller;

import com.uniseek.common.ApiResult;
import com.uniseek.common.PageResult;
import com.uniseek.common.annotation.OperationLog;
import com.uniseek.dto.ApplyRequest;
import com.uniseek.dto.CompleteRequest;
import com.uniseek.dto.UpdateStatusRequest;
import com.uniseek.entity.TaskApplication;
import com.uniseek.service.ApplicationService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import javax.validation.Valid;

/**
 * 投递申请控制器
 */
@RestController
@RequestMapping("/api")
public class ApplicationController {

    @Autowired
    private ApplicationService applicationService;

    /**
     * 求职者投递职位
     * POST /api/applications
     *
     * @param request 投递请求
     * @return 投递记录
     */
    @PostMapping("/applications")
    @OperationLog(module = "投递管理", action = "投递", description = "求职者投递职位")
    public ApiResult<TaskApplication> apply(@Valid @RequestBody ApplyRequest request) {
        TaskApplication application = applicationService.apply(request);
        return ApiResult.success("投递成功", application);
    }

    /**
     * 求职者查看自己的投递列表
     * GET /api/applications/my
     *
     * @param page     页码（默认 1）
     * @param pageSize 每页条数（默认 10）
     * @return 分页结果
     */
    @GetMapping("/applications/my")
    public ApiResult<PageResult<TaskApplication>> getMyApplications(
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "10") int pageSize) {
        PageResult<TaskApplication> result = applicationService.getMyApplications(page, pageSize);
        return ApiResult.success(result);
    }

    /**
     * 投递详情
     * GET /api/applications/{id}
     *
     * @param id 投递记录 ID
     * @return 投递详情
     */
    @GetMapping("/applications/{id}")
    public ApiResult<TaskApplication> getApplicationDetail(@PathVariable Long id) {
        TaskApplication application = applicationService.getApplicationDetail(id);
        return ApiResult.success(application);
    }

    /**
     * HR 查看某职位的投递列表
     * GET /api/tasks/{taskId}/applications
     *
     * @param taskId   职位 ID
     * @param page     页码（默认 1）
     * @param pageSize 每页条数（默认 10）
     * @return 分页结果
     */
    @GetMapping("/tasks/{taskId}/applications")
    public ApiResult<PageResult<TaskApplication>> getTaskApplications(
            @PathVariable Long taskId,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "10") int pageSize) {
        PageResult<TaskApplication> result = applicationService.getTaskApplications(taskId, page, pageSize);
        return ApiResult.success(result);
    }

    /**
     * HR 修改投递状态
     * PUT /api/applications/{id}/status
     *
     * @param id      投递记录 ID
     * @param request 状态更新请求
     * @return 操作结果
     */
    @PutMapping("/applications/{id}/status")
    @OperationLog(module = "投递管理", action = "更新状态", description = "HR 处理投递状态流转")
    public ApiResult<Void> updateStatus(@PathVariable Long id,
                                        @Valid @RequestBody UpdateStatusRequest request) {
        applicationService.updateStatus(id, request);
        return ApiResult.success("状态更新成功", null);
    }

    /**
     * 结算确认
     * PUT /api/applications/{id}/complete
     *
     * @param id      投递记录 ID
     * @param request 结算请求
     * @return 操作结果
     */
    @PutMapping("/applications/{id}/complete")
    @OperationLog(module = "投递管理", action = "结算", description = "结算确认投递完成")
    public ApiResult<Void> complete(@PathVariable Long id,
                                    @Valid @RequestBody CompleteRequest request) {
        applicationService.complete(id, request);
        return ApiResult.success("结算确认成功", null);
    }
}
