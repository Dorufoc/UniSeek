package com.uniseek.controller;

import com.uniseek.common.ApiResult;
import com.uniseek.dto.CategoryVO;
import com.uniseek.service.CategoryService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * 职位分类控制器
 */
@RestController
@RequestMapping("/api/categories")
public class CategoryController {

    @Autowired
    private CategoryService categoryService;

    /**
     * 获取全部分类树
     * GET /api/categories（无需鉴权）
     */
    @GetMapping
    public ApiResult<List<CategoryVO>> getTree() {
        List<CategoryVO> tree = categoryService.getTree();
        return ApiResult.success(tree);
    }
}
