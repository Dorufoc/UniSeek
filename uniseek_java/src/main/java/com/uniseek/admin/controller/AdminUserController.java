package com.uniseek.admin.controller;

import com.uniseek.admin.service.AdminService;
import com.uniseek.common.ApiResult;
import com.uniseek.common.PageResult;
import com.uniseek.entity.User;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 管理后台 —— 用户管理控制器
 */
@RestController
@RequestMapping("/api/admin/users")
public class AdminUserController {

    @Autowired
    private AdminService adminService;

    /**
     * 用户列表（分页）
     * GET /api/admin/users
     *
     * @param page    页码（默认 1）
     * @param pageSize 每页条数（默认 10）
     * @param keyword 关键词（手机号/邮箱/昵称模糊搜索）
     * @param role    角色筛选（0 求职者 / 1 企业 HR）
     * @param status  状态筛选（0 禁用 / 1 正常）
     * @return 用户分页结果
     */
    @GetMapping
    public ApiResult<PageResult<User>> listUsers(
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "10") int pageSize,
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) Integer role,
            @RequestParam(required = false) Integer status) {
        PageResult<User> result = adminService.listUsers(page, pageSize, keyword, role, status);
        return ApiResult.success(result);
    }

    /**
     * 启用/禁用用户
     * PUT /api/admin/users/{id}/status
     *
     * @param id     用户 ID
     * @param status 目标状态（0 禁用 / 1 正常）
     * @return 操作结果
     */
    @PutMapping("/{id}/status")
    public ApiResult<Map<String, Object>> updateUserStatus(
            @PathVariable Long id,
            @RequestParam Integer status) {
        adminService.updateUserStatus(id, status);
        String statusText = status == 0 ? "已禁用" : "已启用";
        Map<String, Object> data = new HashMap<>();
        data.put("id", id);
        data.put("status", status);
        return ApiResult.success("用户" + statusText, data);
    }

    /**
     * 获取所有管理员账号列表
     * GET /api/admin/users/admins
     *
     * @return 管理员用户列表
     */
    @GetMapping("/admins")
    public ApiResult<List<User>> listAdmins() {
        List<User> admins = adminService.listAdmins();
        return ApiResult.success(admins);
    }

    /**
     * 超级管理员修改用户角色
     * PUT /api/admin/users/{id}/role
     *
     * @param id   用户 ID
     * @param role 新角色值
     * @return 操作结果
     */
    @PutMapping("/{id}/role")
    public ApiResult<Map<String, Object>> updateUserRole(
            @PathVariable Long id,
            @RequestParam Integer role) {
        adminService.updateUserRole(id, role);
        Map<String, Object> data = new HashMap<>();
        data.put("id", id);
        data.put("role", role);
        return ApiResult.success("用户角色已更新", data);
    }
}
