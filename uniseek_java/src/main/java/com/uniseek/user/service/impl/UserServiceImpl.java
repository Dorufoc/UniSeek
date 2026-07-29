package com.uniseek.user.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.UpdateWrapper;
import com.uniseek.auth.dto.UserVO;
import com.uniseek.common.ApiResult;
import com.uniseek.common.exception.BusinessException;
import com.uniseek.dao.EnterpriseMapper;
import com.uniseek.dao.FavoriteMapper;
import com.uniseek.dao.TaskApplicationMapper;
import com.uniseek.dao.TaskMapper;
import com.uniseek.dao.UserMapper;
import com.uniseek.entity.Enterprise;
import com.uniseek.entity.Favorite;
import com.uniseek.entity.Task;
import com.uniseek.entity.TaskApplication;
import com.uniseek.entity.User;
import com.uniseek.user.service.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 用户服务实现
 */
@Service
public class UserServiceImpl implements UserService {

    @Autowired
    private UserMapper userMapper;

    @Autowired
    private TaskApplicationMapper taskApplicationMapper;

    @Autowired
    private EnterpriseMapper enterpriseMapper;

    @Autowired
    private FavoriteMapper favoriteMapper;

    @Autowired
    private TaskMapper taskMapper;

    @Override
    @Transactional(rollbackFor = Exception.class)
    public UserVO updateProfile(Long userId, String nickname, String avatarUrl, String phone, String email) {
        // 1. 校验用户是否存在
        User user = userMapper.selectById(userId);
        if (user == null) {
            throw new BusinessException("用户不存在");
        }

        // 2. 如果修改手机号，检查唯一性
        if (phone != null && !phone.trim().isEmpty() && !phone.equals(user.getPhone())) {
            Integer phoneCount = userMapper.selectCount(
                    new LambdaQueryWrapper<User>()
                            .ne(User::getId, userId)
                            .eq(User::getPhone, phone.trim()));
            if (phoneCount > 0) {
                throw new BusinessException(ApiResult.CONFLICT, "该手机号已被其他账号绑定");
            }
        }

        // 3. 如果修改邮箱，检查唯一性
        if (email != null && !email.trim().isEmpty() && !email.equals(user.getEmail())) {
            Integer emailCount = userMapper.selectCount(
                    new LambdaQueryWrapper<User>()
                            .ne(User::getId, userId)
                            .eq(User::getEmail, email.trim()));
            if (emailCount > 0) {
                throw new BusinessException(ApiResult.CONFLICT, "该邮箱已被其他账号绑定");
            }
        }

        // 4. 构建更新条件——只更新非 null 的字段
        UpdateWrapper<User> uw = new UpdateWrapper<>();
        uw.eq("id", userId);

        boolean needUpdate = false;

        if (nickname != null && !nickname.trim().isEmpty()) {
            uw.set("nickname", nickname.trim());
            needUpdate = true;
        }
        if (avatarUrl != null && !avatarUrl.trim().isEmpty()) {
            uw.set("avatar_url", avatarUrl.trim());
            needUpdate = true;
        }
        if (phone != null && !phone.trim().isEmpty() && !phone.equals(user.getPhone())) {
            uw.set("phone", phone.trim());
            needUpdate = true;
        }
        if (email != null && !email.trim().isEmpty() && !email.equals(user.getEmail())) {
            uw.set("email", email.trim());
            needUpdate = true;
        }

        if (needUpdate) {
            uw.set("update_time", LocalDateTime.now());
            userMapper.update(null, uw);
            user = userMapper.selectById(userId);
        }

        // 5. 构建并返回脱敏 VO
        return buildUserVO(user);
    }

    @Override
    public Map<String, Object> getUserStats(Long userId, Integer role) {
        Map<String, Object> stats = new HashMap<>();

        if (role == null) {
            return stats;
        }

        if (role == 0) {
            // 求职者统计：投递总数、面试邀请数（status=1）、收藏总数
            int applications = taskApplicationMapper.selectCount(
                    new LambdaQueryWrapper<TaskApplication>().eq(TaskApplication::getApplicantId, userId));
            stats.put("applications", applications);

            int interviews = taskApplicationMapper.selectCount(
                    new LambdaQueryWrapper<TaskApplication>()
                            .eq(TaskApplication::getApplicantId, userId)
                            .eq(TaskApplication::getStatus, 1));
            stats.put("interviews", interviews);

            int favorites = favoriteMapper.selectCount(
                    new LambdaQueryWrapper<Favorite>().eq(Favorite::getUserId, userId));
            stats.put("favorites", favorites);

        } else if (role == 1) {
            // 招聘者统计覆盖当前账号全部企业记录下的职位，避免企业资质重提后遗漏历史职位的投递数据。
            List<Enterprise> enterprises = enterpriseMapper.selectList(
                    new QueryWrapper<Enterprise>()
                            .eq("user_id", userId)
                            .select("id"));
            if (enterprises.isEmpty()) {
                stats.put("receivedResumes", 0);
                stats.put("interviews", 0);
                stats.put("pending", 0);
                stats.put("activeJobs", 0);
                stats.put("hired", 0);
                return stats;
            }

            // 提取企业 ID 列表
            List<Long> enterpriseIds = new ArrayList<>(enterprises.size());
            for (Enterprise e : enterprises) {
                if (e.getId() != null) {
                    enterpriseIds.add(e.getId());
                }
            }

            // 招聘中的职位数
            int activeJobs = taskMapper.selectCount(
                    new QueryWrapper<Task>()
                            .in("enterprise_id", enterpriseIds)
                            .eq("status", 1));
            stats.put("activeJobs", activeJobs);

            // 查询企业下所有职位 ID（用于投递统计）
            List<Task> tasks = taskMapper.selectList(
                    new QueryWrapper<Task>()
                            .in("enterprise_id", enterpriseIds)
                            .select("id"));
            if (tasks.isEmpty()) {
                stats.put("receivedResumes", 0);
                stats.put("interviews", 0);
                stats.put("pending", 0);
                stats.put("hired", 0);
                return stats;
            }

            List<Long> taskIds = new ArrayList<>(tasks.size());
            for (Task t : tasks) {
                if (t.getId() != null) {
                    taskIds.add(t.getId());
                }
            }

            // 投递总数
            int receivedResumes = taskApplicationMapper.selectCount(
                    new QueryWrapper<TaskApplication>().in("task_id", taskIds));
            stats.put("receivedResumes", receivedResumes);

            // 待面试（status=1）
            int interviews = taskApplicationMapper.selectCount(
                    new QueryWrapper<TaskApplication>()
                            .in("task_id", taskIds)
                            .eq("status", 1));
            stats.put("interviews", interviews);

            // 待定（status=2）
            int pending = taskApplicationMapper.selectCount(
                    new QueryWrapper<TaskApplication>()
                            .in("task_id", taskIds)
                            .eq("status", 2));
            stats.put("pending", pending);

            // 已录用（status=3）
            int hired = taskApplicationMapper.selectCount(
                    new QueryWrapper<TaskApplication>()
                            .in("task_id", taskIds)
                            .eq("status", 3));
            stats.put("hired", hired);
        }

        return stats;
    }

    private UserVO buildUserVO(User user) {
        UserVO vo = new UserVO();
        vo.setId(user.getId());
        vo.setPhone(UserVO.phoneDesensitization(user.getPhone()));
        vo.setEmail(UserVO.emailDesensitization(user.getEmail()));
        vo.setNickname(user.getNickname());
        vo.setAvatarUrl(user.getAvatarUrl());
        vo.setRole(user.getRole());
        vo.setStatus(user.getStatus());
        vo.setCreditScore(user.getCreditScore());
        vo.setLastLoginTime(user.getLastLoginTime());
        vo.setCreateTime(user.getCreateTime());
        return vo;
    }
}
