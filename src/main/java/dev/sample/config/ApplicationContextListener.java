package dev.sample.config;

import dev.sample.dto.*;
import dev.sample.dao.*;
import dev.sample.service.*;
import dev.sample.config.*;
import dev.sample.filter.*;

import javax.servlet.ServletContext;
import javax.servlet.ServletContextEvent;
import javax.servlet.ServletContextListener;
import javax.servlet.annotation.WebListener;
import javax.sql.DataSource;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.zaxxer.hikari.HikariDataSource;

@WebListener
public class ApplicationContextListener implements ServletContextListener {

	private static final Logger log = LoggerFactory.getLogger(ApplicationContextListener.class);

	private HikariDataSource writeDs;
	private HikariDataSource readDs;

	@Override
	public void contextInitialized(ServletContextEvent sce) {
		ServletContext ctx = sce.getServletContext();

		writeDs = HikariDataSourceFactory.createWriteDataSource();
		readDs = HikariDataSourceFactory.createReadDataSource();

		// Backward compatibility: existing code keeps using DATA_SOURCE (write)
		ctx.setAttribute("DATA_SOURCE", writeDs);
		ctx.setAttribute("WRITE_DATA_SOURCE", writeDs);
		ctx.setAttribute("READ_DATA_SOURCE", readDs);

		UserService userService = new UserService(writeDs);
		ctx.setAttribute("USER_SERVICE", userService);

		log.info("HikariCP pools initialized — write: {}, read: {}", writeDs.getJdbcUrl(), readDs.getJdbcUrl());
	}

	@Override
	public void contextDestroyed(ServletContextEvent sce) {
		if (readDs != null) {
			readDs.close();
			log.info("Read pool closed");
		}
		if (writeDs != null) {
			writeDs.close();
			log.info("Write pool closed");
		}
	}

	public static DataSource getDataSource(ServletContext ctx) {
		return (DataSource) ctx.getAttribute("DATA_SOURCE");
	}

	public static DataSource getWriteDataSource(ServletContext ctx) {
		return (DataSource) ctx.getAttribute("WRITE_DATA_SOURCE");
	}

	public static DataSource getReadDataSource(ServletContext ctx) {
		return (DataSource) ctx.getAttribute("READ_DATA_SOURCE");
	}
}
