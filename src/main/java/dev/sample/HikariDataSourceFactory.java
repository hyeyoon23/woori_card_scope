package dev.sample;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.zaxxer.hikari.HikariConfig;
import com.zaxxer.hikari.HikariDataSource;

/**
 * HikariCP DataSource 팩토리.
 * 환경변수 기반으로 write(Source) / read(Replica) 커넥션 풀을 생성한다.
 */
public class HikariDataSourceFactory {

    private static final Logger log = LoggerFactory.getLogger(HikariDataSourceFactory.class);

    // ──────── public factory methods ────────

    /**
     * Write(Source) 용 DataSource 생성.
     * DB_SOURCE_* 환경변수를 사용한다.
     */
    public static HikariDataSource createWriteDataSource() {
        loadDriver();

        String dbName = env("APP_DB_NAME", "card_db");
        String dbParams = env("DB_PARAMS",
                "serverTimezone=Asia/Seoul&characterEncoding=UTF-8&useSSL=false&allowPublicKeyRetrieval=true");

        HikariConfig config = new HikariConfig();
        config.setPoolName("write-pool");
        
        config.setJdbcUrl(buildJdbcUrl(
                env("DB_SOURCE_HOST", "mysql-router"),
                env("DB_SOURCE_PORT", "6446"),
                dbName, dbParams));
        config.setUsername(env("DB_SOURCE_USER", env("APP_DB_USER", "app")));
        config.setPassword(env("DB_SOURCE_PASSWORD", env("APP_DB_PASSWORD", "app1234")));
        
        applyPoolOptions(config, "DB_SOURCE_");

        HikariDataSource ds = new HikariDataSource(config);
        log.info("Write pool created: url={}", config.getJdbcUrl());
        return ds;
    }

    /**
     * Read(Replica) 용 DataSource 생성.
     * DB_REPLICA_* 환경변수를 사용하며, 미설정 시 Source 값으로 fallback.
     */
    public static HikariDataSource createReadDataSource() {
        loadDriver();

        String dbName = env("APP_DB_NAME", "card_db");
        String dbParams = env("DB_PARAMS",
                "serverTimezone=Asia/Seoul&characterEncoding=UTF-8&useSSL=false&allowPublicKeyRetrieval=true");

        HikariConfig config = new HikariConfig();
        config.setPoolName("read-pool");
        
        config.setJdbcUrl(buildJdbcUrl(
                env("DB_REPLICA_HOST", env("DB_SOURCE_HOST", "mysql-router")),
                env("DB_REPLICA_PORT", env("DB_SOURCE_PORT", "6447")),
                dbName, dbParams));
        config.setUsername(env("DB_REPLICA_USER", env("APP_DB_RO_USER", "app_ro")));
        config.setPassword(env("DB_REPLICA_PASSWORD", env("APP_DB_RO_PASSWORD", "app_ro_pw")));
        
        applyPoolOptions(config, "DB_REPLICA_");

        HikariDataSource ds = new HikariDataSource(config);
        log.info("Read pool created: url={}", config.getJdbcUrl());
        return ds;
    }

    // ──────── internal helpers ────────

    private static void loadDriver() {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
        } catch (ClassNotFoundException e) {
            throw new IllegalStateException("MySQL JDBC Driver loading failed", e);
        }
    }

    private static void applyPoolOptions(HikariConfig config, String prefix) {
        config.setMaximumPoolSize(envInt(prefix + "MAX_POOL_SIZE", 10));
        config.setMinimumIdle(envInt(prefix + "MIN_IDLE", 2));
        config.setConnectionTimeout(envLong(prefix + "CONNECTION_TIMEOUT_MS", 3000L));
        config.setIdleTimeout(envLong(prefix + "IDLE_TIMEOUT_MS", 600000L));
        config.setMaxLifetime(envLong(prefix + "MAX_LIFETIME_MS", 1800000L));
    }

    private static String buildJdbcUrl(String host, String port, String dbName, String dbParams) {
        return String.format("jdbc:mysql://%s:%s/%s?%s", host, port, dbName, dbParams);
    }

    // ──────── env util ────────

    static String env(String key, String defaultValue) {
        String value = System.getenv(key);
        return (value == null || value.trim().isEmpty()) ? defaultValue : value.trim();
    }

    static int envInt(String key, int defaultValue) {
        String value = System.getenv(key);
        if (value == null || value.trim().isEmpty()) {
            return defaultValue;
        }
        try {
            return Integer.parseInt(value.trim());
        } catch (NumberFormatException ignored) {
            return defaultValue;
        }
    }

    static long envLong(String key, long defaultValue) {
        String value = System.getenv(key);
        if (value == null || value.trim().isEmpty()) {
            return defaultValue;
        }
        try {
            return Long.parseLong(value.trim());
        } catch (NumberFormatException ignored) {
            return defaultValue;
        }
    }
}
