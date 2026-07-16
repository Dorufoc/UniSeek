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
import com.uniseek.dao.UserMapper;
import com.uniseek.entity.Enterprise;
import com.uniseek.entity.Favorite;
import com.uniseek.entity.TaskApplication;
import com.uniseek.entity.User;
import com.uniseek.user.service.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.HashMap;
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

        if (role != null && role == 0) {
            // 求职者：投递数、面试邀请数
            QueryWrapper<TaskApplication> appWrapper = new QueryWrapper<>();
            appWrapper.eq("applicant_id", userId);
            int applications = taskApplicationMapper.selectCount(appWrapper);
            stats.put("applications", applications);

            QueryWrapper<TaskApplication> interviewWrapper = new QueryWrapper<>();
            interviewWrapper.eq("applicant_id", userId).eq("status", 1);
            int interviews = taskApplicationMapper.selectCount(interviewWrapper);
            stats.put("interviews", interviews);

            QueryWrapper<Favorite> favWrapper = new QueryWrapper<>();
            favWrapper.eq("user_id", userId);
            int favorites = favoriteMapper.selectCount(favWrapper);
            stats.put("favorites", favorites);

        } else if (role != null && role == 1) {
            // 招聘者：通过企业 ID 查询投递数据
            QueryWrapper<Enterprise> entWrapper = new QueryWrapper<>();
            entWrapper.eq("user_id", userId);
            Enterprise enterprise = enterpriseMapper.selectOne(entWrapper);

            if (enterprise != null) {
                QueryWrapper<TaskApplication> receivedWrapper = new QueryWrapper<>();
                receivedWrapper.inSql("task_id", "SELECT id FROM task WHERE enterprise_id = " + enterprise.getId());
                int receivedResumes = taskApplicationMapper.selectCount(receivedWrapper);
                stats.put("receivedResumes", receivedResumes);

                QueryWrapper<TaskApplication> hiredWrapper = new QueryWrapper<>();
                hiredWrapper.inSql("task_id", "SELECT id FROM task WHERE enterprise_id = " + enterprise.getId())
                        .eq("status", 3);
                int hired = taskApplicationMapper.selectCount(hiredWrapper);
                stats.put("hired", hired);
            } else {
                stats.put("receivedResumes", 0);
                stats.put("hired", 0);
            }
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
