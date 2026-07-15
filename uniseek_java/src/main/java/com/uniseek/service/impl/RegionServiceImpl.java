package com.uniseek.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.uniseek.dao.RegionMapper;
import com.uniseek.dto.RegionVO;
import com.uniseek.entity.Region;
import com.uniseek.service.RegionService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * 行政区划服务实现
 */
@Service
public class RegionServiceImpl implements RegionService {

    @Autowired
    private RegionMapper regionMapper;

    @Override
    public List<RegionVO> getProvinces() {
        List<Region> regions = regionMapper.selectList(
                new LambdaQueryWrapper<Region>()
                        .eq(Region::getLevel, 1)
                        .orderByAsc(Region::getSortOrder));
        return toVOList(regions);
    }

    @Override
    public List<RegionVO> getChildren(Long parentId) {
        List<Region> regions = regionMapper.selectList(
                new LambdaQueryWrapper<Region>()
                        .eq(Region::getParentId, parentId)
                        .orderByAsc(Region::getSortOrder));
        return toVOList(regions);
    }

    @Override
    public List<RegionVO> getTree() {
        // 一次性查出所有地区数据
        List<Region> allRegions = regionMapper.selectList(
                new LambdaQueryWrapper<Region>()
                        .orderByAsc(Region::getSortOrder));

        // 按 level 分组
        Map<Integer, List<Region>> levelMap = allRegions.stream()
                .collect(Collectors.groupingBy(Region::getLevel));

        List<Region> provinces = levelMap.getOrDefault(1, new ArrayList<>());
        List<Region> cities = levelMap.getOrDefault(2, new ArrayList<>());
        List<Region> districts = levelMap.getOrDefault(3, new ArrayList<>());

        // 组装三级树形结构
        List<RegionVO> tree = toVOList(provinces);

        // 构建 parentId -> List<Region> 映射（市、区）
        Map<Long, List<Region>> cityMap = cities.stream()
                .collect(Collectors.groupingBy(Region::getParentId));
        Map<Long, List<Region>> districtMap = districts.stream()
                .collect(Collectors.groupingBy(Region::getParentId));

        for (RegionVO province : tree) {
            // 挂载市
            List<Region> cityList = cityMap.get(province.getId());
            if (cityList != null) {
                List<RegionVO> cityVOs = toVOList(cityList);
                province.setChildren(cityVOs);
                // 挂载区县
                for (RegionVO city : cityVOs) {
                    List<Region> districtList = districtMap.get(city.getId());
                    if (districtList != null) {
                        city.setChildren(toVOList(districtList));
                    }
                }
            } else {
                // 直辖市没有市级节点，直接将区县挂到省下
                List<Region> districtList = districtMap.get(province.getId());
                if (districtList != null) {
                    province.setChildren(toVOList(districtList));
                }
            }
        }

        return tree;
    }

    /**
     * Region 实体列表 → RegionVO 列表
     */
    private List<RegionVO> toVOList(List<Region> regions) {
        List<RegionVO> voList = new ArrayList<>(regions.size());
        for (Region region : regions) {
            RegionVO vo = new RegionVO();
            vo.setId(region.getId());
            vo.setName(region.getName());
            vo.setLevel(region.getLevel());
            voList.add(vo);
        }
        return voList;
    }
}
