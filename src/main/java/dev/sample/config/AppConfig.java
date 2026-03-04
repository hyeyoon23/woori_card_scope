package dev.sample.config;

import javax.sql.DataSource;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.ComponentScan;
import org.springframework.context.annotation.Configuration;

@Configuration
@ComponentScan("dev.sample")
public class AppConfig {

	// ─────────────────────────────────────────
    // HikariCp
    // ─────────────────────────────────────────

	@Bean("writeDataSource")
    public DataSource writeDataSource() {
        return HikariDataSourceFactory.createWriteDataSource();
    }
    
    @Bean("readDataSource") 
    public DataSource readDataSource() {
        return HikariDataSourceFactory.createReadDataSource();
    }

}
