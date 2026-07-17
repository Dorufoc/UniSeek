package com.uniseek.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.uniseek.common.ApiResult;
import com.uniseek.common.PageResult;
import com.uniseek.operationlog.annotation.OperationLog;
import com.uniseek.common.exception.BusinessException;
import com.uniseek.constant.RoleConstant;
import com.uniseek.dao.EnterpriseMapper;
import com.uniseek.dao.TaskMapper;
import com.uniseek.dto.TaskRequest;
import com.uniseek.dto.TaskSearchRequest;
import com.uniseek.dto.TaskVO;
import com.uniseek.entity.Enterprise;
import com.uniseek.entity.Task;
import com.uniseek.service.TaskService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

/**
 * 职位任务服务实现
 */
@Service
public class TaskServiceImpl implements TaskService {

    @Autowired
    private TaskMapper taskMapper;

    @Autowired
    private EnterpriseMapper enterpriseMapper;

    @Autowired
    private ObjectMapper objectMapper;

    @Override
    @Transactional(rollbackFor = Exception.class)
    @OperationLog(operationType = "TASK_PUBLISH", targetType = "TASK")
    public Task create(Long enterpriseId, TaskRequest request) {
        // 1. 校验企业已认证
        Enterprise enterprise = enterpriseMapper.selectById(enterpriseId);
        if (enterprise == null) {
            throw new BusinessException("企业信息不存在");
        }
        if (enterprise.getAuditStatus() != 1) {
            throw new BusinessException("企业尚未通过资质认证，无法发布职位");
        }

        // 2. 校验截止时间必须在当前时间之后
        if (request.getDeadline() != null && request.getDeadline().isBefore(LocalDateTime.now())) {
            throw new BusinessException("报名截止时间必须在当前时间之后");
        }

        // 3. 构建职位实体
        Task task = new Task();
        task.setEnterpriseId(enterpriseId);
        task.setCategoryId(request.getCategoryId());
        task.setRegionId(request.getRegionId());
        task.setTitle(request.getTitle().trim());
        task.setDescription(request.getDescription());
        task.setSalaryMin(request.getSalaryMin());
        task.setSalaryMax(request.getSalaryMax());
        task.setSalaryUnit(request.getSalaryUnit());
        task.setJobType(request.getJobType());
        task.setTotalQuota(request.getTotalQuota());
        task.setRemainingQuota(request.getTotalQuota()); // 初始 = 总名额
        task.setAddress(request.getAddress());
        // 将 List<String> tag 转换为 JSON 字符串存入数据库
        if (request.getTag() != null && !request.getTag().isEmpty()) {
            try {
                task.setTag(objectMapper.writeValueAsString(request.getTag()));
            } catch (Exception e) {
                throw new BusinessException("标签格式转换失败");
            }
        }
        task.setLongitude(request.getLongitude());
        task.setLatitude(request.getLatitude());
        task.setStatus(0); // 待审核
        task.setVersion(1);
        task.setDeadline(request.getDeadline());
        task.setCreateTime(LocalDateTime.now());
        task.setUpdateTime(LocalDateTime.now());

        // 4. 插入职位
        taskMapper.insert(task);

        return task;
    }

    @Override
    public PageResult<TaskVO> search(TaskSearchRequest req) {
        // 校验分页参数
        if (req.getPage() < 1) {
            req.setPage(1);
        }
        if (req.getPageSize() < 1 || req.getPageSize() > 100) {
            req.setPageSize(10);
        }

        // 创建 MyBatis-Plus 分页对象
        Page<TaskVO> page = new Page<>(req.getPage(), req.getPageSize());
        // 开启 COUNT 优化（默认 true），自动去除 ORDER BY 避免 COUNT 报错

        // 执行分页查询
        IPage<TaskVO> taskPage = taskMapper.selectPageByCondition(page, req);

        return PageResult.of(taskPage);
    }

    @Override
    public TaskVO getDetail(Long id, Long userId) {
        TaskVO vo = taskMapper.selectDetailById(id, userId);
        if (vo == null) {
            throw new BusinessException(ApiResult.NOT_FOUND, "职位不存在");
        }
        return vo;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    @OperationLog(operationType = "TASK_PUBLISH", targetType = "TASK", targetIdExpression = "#id")
    public Task update(Long enterpriseId, Long id, TaskRequest request) {
        // 1. 查询职位
        Task task = taskMapper.selectById(id);
        if (task == null) {
            throw new BusinessException(ApiResult.NOT_FOUND, "职位不存在");
        }

        // 2. 校验企业归属
        if (!task.getEnterpriseId().equals(enterpriseId)) {
            throw new BusinessException(ApiResult.FORBIDDEN, "无权操作该职位");
        }

        // 3. 校验状态：仅待审核（0）和已下架（4）可更新
        if (task.getStatus() != 0 && task.getStatus() != 4) {
            throw new BusinessException("仅待审核或已下架的职位可以编辑");
        }

        // 4. 校验截止时间
        if (request.getDeadline() != null && request.getDeadline().isBefore(LocalDateTime.now())) {
            throw new BusinessException("报名截止时间必须在当前时间之后");
        }

        // 5. 更新字段
        task.setCategoryId(request.getCategoryId());
        task.setRegionId(request.getRegionId());
        task.setTitle(request.getTitle().trim());
        task.setDescription(request.getDescription());
        task.setSalaryMin(request.getSalaryMin());
        task.setSalaryMax(request.getSalaryMax());
        task.setSalaryUnit(request.getSalaryUnit());
        task.setJobType(request.getJobType());
        task.setTotalQuota(request.getTotalQuota());
        task.setRemainingQuota(request.getTotalQuota()); // 重新设置剩余名额
        task.setAddress(request.getAddress());
        // 将 List<String> tag 转换为 JSON 字符串存入数据库
        if (request.getTag() != null && !request.getTag().isEmpty()) {
            try {
                task.setTag(objectMapper.writeValueAsString(request.getTag()));
            } catch (Exception e) {
                throw new BusinessException("标签格式转换失败");
            }
        } else {
            task.setTag(null);
        }
        task.setLongitude(request.getLongitude());
        task.setLatitude(request.getLatitude());
        task.setDeadline(request.getDeadline());
        task.setUpdateTime(LocalDateTime.now());

        // 6. 乐观锁更新
        int rows = taskMapper.updateById(task);
        if (rows == 0) {
            throw new BusinessException("更新失败，数据已被其他操作修改，请刷新后重试");
        }

        return task;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    @OperationLog(operationType = "TASK_OFFLINE", targetType = "TASK", targetIdExpression = "#id")
    public void updateStatus(Long userId, Integer userRole, Long id, Integer targetStatus) {
        // 1. 查询职位
        Task task = taskMapper.selectById(id);
        if (task == null) {
            throw new BusinessException(ApiResult.NOT_FOUND, "职位不存在");
        }

        // 2. 校验角色权限
	    if (userRole == RoleConstant.HR) {
	            // HR 角色：只能下架自己的职位
	            // 查询企业 ID
	            Enterprise enterprise = enterpriseMapper.selectOne(
	                    new LambdaQueryWrapper<Enterprise>()
	                            .eq(Enterprise::getUserId, userId));
	            if (enterprise == null || !task.getEnterpriseId().equals(enterprise.getId())) {
	                throw new BusinessException(ApiResult.FORBIDDEN, "无权操作该职位");
	            }
	            if (targetStatus != 4 && targetStatus != 1) {
	                throw new BusinessException("HR 只能上架或下架职位");
	            }
	        } else if (userRole == RoleConstant.ADMIN || userRole == RoleConstant.SUPER_ADMIN) {
	            // Admin 角色：可审核通过（1）或下架（4）
	            if (targetStatus != 1 && targetStatus != 4) {
	                throw new BusinessException("管理员可将职位审核通过或下架");
	            }
        } else {
            throw new BusinessException(ApiResult.FORBIDDEN, "无权操作职位状态");
        }

        // 3. 状态流转校验
        if (targetStatus == 1 && task.getStatus() != 0 && task.getStatus() != 4) {
            throw new BusinessException("仅待审核或已下架的职位可上架");
        }
        if (targetStatus == 4 && task.getStatus() == 3) {
            throw new BusinessException("已截止的职位无法下架");
        }

        // 4. 更新状态
        task.setStatus(targetStatus);
        task.setUpdateTime(LocalDateTime.now());

        int rows = taskMapper.updateById(task);
        if (rows == 0) {
            throw new BusinessException("操作失败，数据已被其他操作修改，请刷新后重试");
        }
    }

    @Override
    public PageResult<TaskVO> getEnterpriseTasks(Long enterpriseId) {
        // 查询本企业所有职位
        List<TaskVO> list = taskMapper.selectEnterpriseTasks(enterpriseId);
        return new PageResult<>(list, list.size(), 1, list.size(), 1);
    }

    @Override
    public List<TaskVO> getPublishedEnterpriseTasks(Long enterpriseId) {
        return taskMapper.selectPublishedEnterpriseTasks(enterpriseId);
    }

    @Override
    public List<String> getAllTags() {
        return taskMapper.selectAllTags();
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void resubmit(Long userId, Long id) {
        Task task = taskMapper.selectById(id);
        if (task == null) {
            throw new BusinessException(ApiResult.NOT_FOUND, "职位不存在");
        }
        // 校验企业归属
        Enterprise enterprise = enterpriseMapper.selectOne(
                new LambdaQueryWrapper<Enterprise>()
                        .eq(Enterprise::getUserId, userId));
        if (enterprise == null || !task.getEnterpriseId().equals(enterprise.getId())) {
            throw new BusinessException(ApiResult.FORBIDDEN, "无权操作该职位");
        }
        // 仅已驳回的职位可重新提交
        if (task.getStatus() != 0 || task.getRejectReason() == null) {
            throw new BusinessException("仅已驳回的职位可重新提交审核");
        }
        // 更新时间戳，驳回原因保留供管理员参考
        task.setUpdateTime(LocalDateTime.now());
        taskMapper.updateById(task);
    }
}
