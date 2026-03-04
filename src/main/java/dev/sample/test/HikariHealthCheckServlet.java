package dev.sample.test;

import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

import javax.servlet.ServletContext;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.sql.DataSource;

@WebServlet("/test/hikari")
public class HikariHealthCheckServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

	@Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        resp.setContentType("text/plain; charset=UTF-8");
        PrintWriter out = resp.getWriter();

        ServletContext ctx = getServletContext();
        Object obj = ctx.getAttribute("DATA_SOURCE");
        if (obj == null) {
            resp.setStatus(500);
            out.println("FAIL: DATA_SOURCE not found in ServletContext");
            return;
        }

        DataSource ds = (DataSource) obj;

        String sql = "SELECT 1";

        long start = System.currentTimeMillis();
        try (Connection con = ds.getConnection();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            rs.next();
            int v = rs.getInt(1);

            long elapsed = System.currentTimeMillis() - start;
            out.println("Status: OK");
            out.println("queryResult=" + v);
            out.println("elapsedMs=" + elapsed);
            out.println("connClass=" + con.getClass().getName());
        } catch (Exception e) {
            resp.setStatus(500);
            out.println("FAIL: " + e.getClass().getName() + " - " + e.getMessage());
        }
    }
}
