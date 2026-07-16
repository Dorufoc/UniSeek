package com.uniseek.user.controller;

import com.uniseek.auth.dto.UserVO;
import com.uniseek.common.ApiResult;
import com.uniseek.common.util.UserContext;
import com.uniseek.user.service.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

/**
 * 用户控制器——处理用户资料相关请求
 */
@RestController
@RequestMapping("/api/user")
public class UserController {

    @Autowired
    private UserService userService;

    /**
     * 获取用户统计数据
     * GET /api/user/stats
     *
     * @return 统计数据（求职者：applications/interviews/favorites；招聘者：receivedResumes/hired）
     */
    @GetMapping("/stats")
    public ApiResult<Map<String, Object>> getUserStats() {
        Long userId = UserContext.getUserId();
        Integer role = UserContext.getRole();
        Map<String, Object> stats = userService.getUserStats(userId, role);
        return ApiResult.success(stats);
    }

    /**
     * 更新用户资料（昵称、头像、手机号、邮箱）
     */
    @PutMapping("/profile")
    public ApiResult<UserVO> updateProfile(
            @RequestParam(required = false) String nickname,
            @RequestParam(required = false) String avatarUrl,
            @RequestParam(required = false) String phone,
            @RequestParam(required = false) String email) {

        Long userId = UserContext.getUserId();
        UserVO userVO = userService.updateProfile(userId, nickname, avatarUrl, phone, email);
        return ApiResult.success("更新成功", userVO);
    }
}
