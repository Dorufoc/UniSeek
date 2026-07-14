package com.uniseek.controller;

import com.uniseek.common.ApiResult;
import com.uniseek.dto.RegionVO;
import com.uniseek.service.RegionService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * 地区数据控制器（无需鉴权）
 */
@RestController
@RequestMapping("/api/region")
public class RegionController {

    @Autowired
    private RegionService regionService;

    /**
     * 获取所有省级行政区划
     * GET /api/region/provinces
     */
    @GetMapping("/provinces")
    public ApiResult<List<RegionVO>> getProvinces() {
        List<RegionVO> provinces = regionService.getProvinces();
        return ApiResult.success(provinces);
    }

    /**
     * 获取指定父级下的子级行政区划
     * GET /api/region/children/{parentId}
     */
    @GetMapping("/children/{parentId}")
    public ApiResult<List<RegionVO>> getChildren(@PathVariable Long parentId) {
        List<RegionVO> children = regionService.getChildren(parentId);
        return ApiResult.success(children);
    }

    /**
     * 获取完整的省/市/区三级树形结构
     * GET /api/region/tree
     */
    @GetMapping("/tree")
    public ApiResult<List<RegionVO>> getTree() {
        List<RegionVO> tree = regionService.getTree();
        return ApiResult.success(tree);
    }
}
