package com.uniseek.service;

import com.uniseek.dto.RegionVO;

import java.util.List;

/**
 * 行政区划服务接口
 */
public interface RegionService {

    /**
     * 获取所有省级行政区划
     */
    List<RegionVO> getProvinces();

    /**
     * 获取指定父级下的子级行政区划
     *
     * @param parentId 父级行政区划 ID
     */
    List<RegionVO> getChildren(Long parentId);

    /**
     * 获取完整的省/市/区三级树形结构
     */
    List<RegionVO> getTree();
}
