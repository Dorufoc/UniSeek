package com.uniseek.service;

import com.uniseek.common.PageResult;
import com.uniseek.dto.ApplyRequest;
import com.uniseek.dto.CompleteRequest;
import com.uniseek.dto.UpdateStatusRequest;
import com.uniseek.entity.TaskApplication;

/**
 * 投递申请服务接口
 */
public interface ApplicationService {

    /**
     * 求职者投递职位
     * <p>
     * 前置条件：
     * <ul>
     *   <li>用户已实名认证</li>
     *   <li>用户已有简历</li>
     *   <li>职位处于招聘状态（status=1）、未截止、有名额</li>
     *   <li>未重复投递该职位</li>
     * </ul>
     * 投递后自动创建聊天会话并发送通知给 HR
     *
     * @param request 投递请求
     * @return 投递记录
     */
    TaskApplication apply(ApplyRequest request);

    /**
     * HR 处理投递状态流转
     * <p>
     * 校验当前用户为该职位所属企业的 HR，
     * 通过状态机校验后执行状态更新。
     * 录用操作会触发乐观锁名额扣减。
     *
     * @param id      投递记录 ID
     * @param request 状态更新请求
     */
    void updateStatus(Long id, UpdateStatusRequest request);

    /**
     * 结算确认（将已录用状态变为已完成）
     *
     * @param id      投递记录 ID
     * @param request 结算请求
     */
    void complete(Long id, CompleteRequest request);

    /**
     * 求职者查看自己的投递列表（分页）
     *
     * @param page     页码
     * @param pageSize 每页条数
     * @return 分页结果
     */
    PageResult<TaskApplication> getMyApplications(int page, int pageSize);

    /**
     * 投递详情（含简历快照解析信息）
     *
     * @param id 投递记录 ID
     * @return 投递详情
     */
    TaskApplication getApplicationDetail(Long id);

    /**
     * HR 查看某职位的投递列表（分页）
     *
     * @param taskId   职位 ID
     * @param page     页码
     * @param pageSize 每页条数
     * @return 分页结果
     */
    PageResult<TaskApplication> getTaskApplications(Long taskId, int page, int pageSize);
}
