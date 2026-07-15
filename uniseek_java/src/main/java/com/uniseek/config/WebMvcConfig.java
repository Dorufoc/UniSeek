package com.uniseek.config;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.InterceptorRegistry;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.File;

/**
 * Web MVC 配置 —— 拦截器、CORS、静态资源映射
 */
@Configuration
public class WebMvcConfig implements WebMvcConfigurer {

    private static final Logger log = LoggerFactory.getLogger(WebMvcConfig.class);

    @Autowired
    private JwtAuthInterceptor jwtAuthInterceptor;

    @Value("${upload.path:./upload}")
    private String uploadPath;

    @Override
    public void addInterceptors(InterceptorRegistry registry) {
        registry.addInterceptor(jwtAuthInterceptor)
                .addPathPatterns("/api/**")
                .excludePathPatterns(
                        "/api/auth/register",
                        "/api/auth/login",
                        "/api/region/**",
                        "/api/files/**"
                );
    }

    @Override
    public void addCorsMappings(CorsRegistry registry) {
        registry.addMapping("/**")
                .allowedOrigins("*")
                .allowedMethods("*")
                .allowedHeaders("*");
    }

    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        File uploadDir = new File(uploadPath).getAbsoluteFile();
        if (!uploadDir.exists()) {
            boolean created = uploadDir.mkdirs();
            log.info("上传目录 {} 不存在，{}", uploadDir.getPath(), created ? "已自动创建" : "创建失败");
        }
        String absoluteUri = uploadDir.toURI().toString();
        log.info("静态资源映射: /api/files/** -> {}", absoluteUri);
        registry.addResourceHandler("/api/files/**")
                .addResourceLocations(absoluteUri);
    }
}
