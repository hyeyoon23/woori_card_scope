package dev.sample.config;

import javax.servlet.ServletContext;
import javax.servlet.ServletContextEvent;
import javax.servlet.ServletContextListener;
import javax.servlet.annotation.WebListener;
import javax.sql.DataSource;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.annotation.AnnotationConfigApplicationContext;

@WebListener
public class ApplicationContextListener implements ServletContextListener {
	
    private AnnotationConfigApplicationContext springContext;


	private static final Logger log = LoggerFactory.getLogger(ApplicationContextListener.class);
	
	@Override
	public void contextInitialized(ServletContextEvent sce) {
        springContext = new AnnotationConfigApplicationContext(AppConfig.class);
        sce.getServletContext().setAttribute("SPRING_CONTEXT", springContext);
        log.info("Spring context initialized");


	}

	@Override
	public void contextDestroyed(ServletContextEvent sce) {
		if (springContext != null) {
            springContext.close(); // DataSource 풀도 여기서 같이 정리됨
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
