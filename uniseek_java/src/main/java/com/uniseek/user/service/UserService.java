package com.uniseek.user.service;

import com.uniseek.auth.dto.UserVO;

import java.util.Map;

/**
 * 用户服务接口
 */
public interface UserService {

    /**
     * 更新用户资料（昵称、头像、手机号、邮箱）
     *
     * @param userId    用户 ID
     * @param nickname  新昵称（可选，为 null 则不更新）
     * @param avatarUrl 新头像 URL（可选，为 null 则不更新）
     * @param phone     新手机号（可选，为 null 则不更新）
     * @param email     新邮箱（可选，为 null 则不更新）
     * @return 脱敏后的用户信息 VO
     */
    UserVO updateProfile(Long userId, String nickname, String avatarUrl, String phone, String email);

    /**
     * 获取用户统计数据（投递数、面试邀请数、收藏数 / 收到简历数、已录取数）
     *
     * @param userId 用户 ID
     * @param role   用户角色
     * @return 统计数据 Map
     */
    Map<String, Object> getUserStats(Long userId, Integer role);
}
