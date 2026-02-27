<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.*" %>

<%
  // ===== 서버에서 넘겨준 데이터 (예상) =====
  // members: List<MemberSummaryDto>  (아래에서는 Map 형태로도 동작하게 작성)
  // totalCount: Integer
  // page: Integer (1-based)
  // pageSize: Integer
  // filters: Map<String, String> ex) rank, age, gender, region, q

  Object membersObj = request.getAttribute("members");
  List<?> members = (membersObj instanceof List) ? (List<?>) membersObj : Collections.emptyList();

  Integer totalCountObj = (Integer) request.getAttribute("totalCount");
  int totalCount = (totalCountObj != null) ? totalCountObj : 0;

  Integer pageObj = (Integer) request.getAttribute("page");
  int page = (pageObj != null) ? pageObj : 1;

  Integer pageSizeObj = (Integer) request.getAttribute("pageSize");
  int pageSize = (pageSizeObj != null) ? pageSizeObj : 10;

  @SuppressWarnings("unchecked")
  Map<String, String> filters = (Map<String, String>) request.getAttribute("filters");
  if (filters == null) filters = new HashMap<>();

  String rank = filters.getOrDefault("rank", "");
  String age = filters.getOrDefault("age", "");
  String gender = filters.getOrDefault("gender", "");
  String region = filters.getOrDefault("region", "");
  String q = filters.getOrDefault("q", "");

  int from = totalCount == 0 ? 0 : (page - 1) * pageSize + 1;
  int to = Math.min(page * pageSize, totalCount);

  String ctx = request.getContextPath(); // 컨텍스트 경로 대응
%>

<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8" />
  <title>Woori Card Scope</title>
  <meta name="viewport" content="width=device-width, initial-scale=1" />

  <style>
    :root{
      --bg: #ffffff;
      --text: #0f172a;          /* slate-900 */
      --muted: #64748b;         /* slate-500 */
      --line: #e5e7eb;          /* gray-200 */
      --card: #ffffff;
      --chip-bg: #eff6ff;       /* blue-50 */
      --chip-fg: #2563eb;       /* blue-600 */
      --primary: #1e3a8a;       /* indigo-900 */
      --primary-2: #1d4ed8;     /* blue-700 */
      --soft: #f8fafc;          /* slate-50 */
      --shadow: 0 8px 30px rgba(15, 23, 42, 0.06);
      --radius: 14px;
    }

    *{ box-sizing: border-box; }
    body{
      margin: 0;
      background: var(--bg);
      color: var(--text);
      font-family: ui-sans-serif, system-ui, -apple-system, Segoe UI, Roboto, "Apple SD Gothic Neo", "Noto Sans KR", Arial, "Helvetica Neue", sans-serif;
    }

    .container{
      max-width: 1200px;
      margin: 0 auto;
      padding: 34px 22px 60px;
    }

    /* Header */
    .title{
      font-size: 44px;
      font-weight: 800;
      letter-spacing: -0.02em;
      color: #1e3a8a;
      margin: 0;
    }
    .subtitle{
      margin: 10px 0 26px;
      color: var(--muted);
      font-size: 16px;
      line-height: 1.6;
    }

    /* Filter card */
    .filter-card{
      background: var(--card);
      border: 1px solid var(--line);
      border-radius: var(--radius);
      box-shadow: var(--shadow);
      padding: 18px 18px 16px;
    }
    .filter-grid{
      display: grid;
      grid-template-columns: 1.1fr 1.1fr 1fr 1.2fr 1.6fr auto auto;
      gap: 14px;
      align-items: end;
    }
    .field label{
      display: block;
      font-size: 13px;
      font-weight: 600;
      color: #334155;
      margin: 0 0 8px;
    }
    .control{
      width: 100%;
      height: 44px;
      border: 1px solid var(--line);
      border-radius: 12px;
      padding: 0 12px;
      background: #f8fafc;
      color: var(--text);
      outline: none;
    }
    .control:focus{
      border-color: #c7d2fe;
      box-shadow: 0 0 0 3px rgba(99,102,241,0.12);
      background: #ffffff;
    }

    .search-wrap{
      position: relative;
    }
    .search-wrap .control{
      padding-left: 40px;
    }
    .search-icon{
      position: absolute;
      left: 12px;
      top: 50%;
      transform: translateY(-50%);
      width: 18px;
      height: 18px;
      color: #94a3b8;
    }

    .btn{
      height: 44px;
      border-radius: 12px;
      padding: 0 14px;
      border: 1px solid var(--line);
      background: #fff;
      color: #111827;
      font-weight: 700;
      cursor: pointer;
      display: inline-flex;
      align-items: center;
      gap: 8px;
      white-space: nowrap;
    }
    .btn:hover{ background: #f8fafc; }
    .btn-primary{
      background: var(--primary);
      border-color: var(--primary);
      color: #fff;
      padding: 0 16px;
    }
    .btn-primary:hover{ background: #172554; }

    .btn svg{ width: 18px; height: 18px; }

    .meta{
      margin: 16px 2px 14px;
      color: var(--muted);
      font-size: 14px;
    }

    /* Table card */
    .table-card{
      margin-top: 10px;
      background: var(--card);
      border: 1px solid var(--line);
      border-radius: var(--radius);
      box-shadow: var(--shadow);
      overflow: hidden;
    }

    table{
      width: 100%;
      border-collapse: separate;
      border-spacing: 0;
    }
    thead th{
      text-align: left;
      font-size: 12px;
      letter-spacing: 0.08em;
      text-transform: uppercase;
      color: #64748b;
      background: #f8fafc;
      border-bottom: 1px solid var(--line);
      padding: 16px 16px;
    }
    tbody td{
      padding: 18px 16px;
      border-bottom: 1px solid #f1f5f9;
      color: #0f172a;
      font-size: 15px;
      vertical-align: middle;
    }
    tbody tr:hover{
      background: #fafafa;
    }

    .id{
      font-weight: 800;
      letter-spacing: 0.02em;
    }

    /* Rank badge */
    .badge{
      display: inline-flex;
      align-items: center;
      height: 28px;
      padding: 0 12px;
      border-radius: 999px;
      font-size: 13px;
      font-weight: 800;
      border: 1px solid transparent;
    }
    .rank-gold{
      color: #b45309;
      background: #fffbeb;
      border-color: #fde68a;
    }
    .rank-platinum{
      color: #334155;
      background: #f1f5f9;
      border-color: #e2e8f0;
    }
    .rank-vip{
      color: #1d4ed8;
      background: #eff6ff;
      border-color: #bfdbfe;
    }
    .rank-vvip{
      color: #0f172a;
      background: #0f172a;
      border-color: #0f172a;
      color: #fff;
    }

    /* Spending type chip */
    .chip{
      display: inline-flex;
      align-items: center;
      height: 28px;
      padding: 0 12px;
      border-radius: 999px;
      font-size: 13px;
      font-weight: 700;
      background: var(--chip-bg);
      color: var(--chip-fg);
      border: 1px solid #bfdbfe;
    }

    /* Action button */
    .action{
      width: 42px;
      height: 42px;
      border-radius: 12px;
      border: 1px solid var(--line);
      background: #fff;
      display: inline-flex;
      align-items: center;
      justify-content: center;
      cursor: pointer;
    }
    .action:hover{
      background: #f8fafc;
    }
    .action svg{
      width: 18px;
      height: 18px;
      color: #1e3a8a;
    }

    /* Pagination */
    .pagination{
      display: flex;
      justify-content: flex-end;
      gap: 8px;
      padding: 14px 16px;
      background: #fff;
    }
    .page-link{
      height: 40px;
      min-width: 40px;
      padding: 0 12px;
      border-radius: 12px;
      border: 1px solid var(--line);
      display: inline-flex;
      align-items: center;
      justify-content: center;
      color: #0f172a;
      text-decoration: none;
      font-weight: 700;
      background: #fff;
    }
    .page-link:hover{ background: #f8fafc; }
    .page-link.active{
      background: #eef2ff;
      border-color: #c7d2fe;
      color: #1e3a8a;
    }

    /* Responsive */
    @media (max-width: 1100px){
      .filter-grid{
        grid-template-columns: 1fr 1fr;
      }
      .btn, .btn-primary{
        width: 100%;
        justify-content: center;
      }
    }
  </style>
</head>

<body>
  <div class="container">
    <h1 class="title">Woori Card Scope</h1>
    <div class="subtitle">Member Rank Growth &amp; Spending Insight Analytics Platform</div>

    <!-- Filters -->
    <form class="filter-card" method="get" action="<%= ctx %>/members">
      <div class="filter-grid">
        <div class="field">
          <label for="rank">Member Rank</label>
          <select class="control" id="rank" name="rank">
            <option value="" <%= rank.isEmpty() ? "selected" : "" %>>All Ranks</option>
            <option value="GOLD" <%= "GOLD".equals(rank) ? "selected" : "" %>>Gold</option>
            <option value="PLATINUM" <%= "PLATINUM".equals(rank) ? "selected" : "" %>>Platinum</option>
            <option value="VIP" <%= "VIP".equals(rank) ? "selected" : "" %>>VIP</option>
            <option value="VVIP" <%= "VVIP".equals(rank) ? "selected" : "" %>>VVIP</option>
          </select>
        </div>

        <div class="field">
          <label for="age">Age Group</label>
          <select class="control" id="age" name="age">
            <option value="" <%= age.isEmpty() ? "selected" : "" %>>All Ages</option>
            <option value="20-29" <%= "20-29".equals(age) ? "selected" : "" %>>20-29</option>
            <option value="30-39" <%= "30-39".equals(age) ? "selected" : "" %>>30-39</option>
            <option value="40-49" <%= "40-49".equals(age) ? "selected" : "" %>>40-49</option>
            <option value="50-59" <%= "50-59".equals(age) ? "selected" : "" %>>50-59</option>
            <option value="60+" <%= "60+".equals(age) ? "selected" : "" %>>60+</option>
          </select>
        </div>

        <div class="field">
          <label for="gender">Gender</label>
          <select class="control" id="gender" name="gender">
            <option value="" <%= gender.isEmpty() ? "selected" : "" %>>All</option>
            <option value="M" <%= "M".equals(gender) ? "selected" : "" %>>Male</option>
            <option value="F" <%= "F".equals(gender) ? "selected" : "" %>>Female</option>
          </select>
        </div>

        <div class="field">
          <label for="region">Region</label>
          <select class="control" id="region" name="region">
            <option value="" <%= region.isEmpty() ? "selected" : "" %>>All Regions</option>
            <option value="Seoul" <%= "Seoul".equals(region) ? "selected" : "" %>>Seoul</option>
            <option value="Incheon" <%= "Incheon".equals(region) ? "selected" : "" %>>Incheon</option>
            <option value="Busan" <%= "Busan".equals(region) ? "selected" : "" %>>Busan</option>
            <option value="Daegu" <%= "Daegu".equals(region) ? "selected" : "" %>>Daegu</option>
            <option value="Gwangju" <%= "Gwangju".equals(region) ? "selected" : "" %>>Gwangju</option>
          </select>
        </div>

        <div class="field search-wrap">
          <label for="q">Customer ID</label>
          <svg class="search-icon" viewBox="0 0 24 24" fill="none" aria-hidden="true">
            <path d="M21 21l-4.3-4.3m1.8-5.2a7 7 0 11-14 0 7 7 0 0114 0z"
                  stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
          </svg>
          <input class="control" id="q" name="q" value="<%= q %>" placeholder="Search by ID..." />
        </div>

        <a class="btn" href="<%= ctx %>/members">
          <svg viewBox="0 0 24 24" fill="none" aria-hidden="true">
            <path d="M4 4v6h6M20 20v-6h-6M20 9a8 8 0 00-14.9-3M4 15a8 8 0 0014.9 3"
                  stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
          </svg>
          Reset
        </a>

        <button class="btn btn-primary" type="submit">Apply</button>
      </div>
    </form>

    <div class="meta">
      Showing <%= from %>-<%= to %> of <%= totalCount %> customers
    </div>

    <!-- Table -->
    <div class="table-card">
      <table>
        <thead>
          <tr>
            <th style="width: 160px;">Customer ID</th>
            <th style="width: 160px;">Member Rank</th>
            <th style="width: 120px;">Age Group</th>
            <th style="width: 120px;">Gender</th>
            <th style="width: 160px;">Region</th>
            <th style="width: 180px;">Total Spending</th>
            <th>Spending Type</th>
            <th style="width: 90px; text-align:center;">Action</th>
          </tr>
        </thead>

        <tbody>
          <%
            if (members.isEmpty()) {
          %>
            <tr>
              <td colspan="8" style="text-align:center; padding: 28px; color:#64748b;">
                No customers found.
              </td>
            </tr>
          <%
            } else {
              for (Object obj : members) {
                // DTO를 모르는 상태에서도 돌아가게: reflection 없이, Map 형태도 허용
                // 권장: MemberSummaryDto에 getCustomerId(), getRank(), getAgeGroup(), getGender(), getRegion(), getTotalSpending(), getSpendingType() 구현
                String customerId = "";
                String r = "";
                String ageGroup = "";
                String g = "";
                String reg = "";
                String totalSpending = "";
                String spendingType = "";

                try {
                  // DTO 방식
                  customerId = String.valueOf(obj.getClass().getMethod("getCustomerId").invoke(obj));
                  r = String.valueOf(obj.getClass().getMethod("getMemberRank").invoke(obj));
                  ageGroup = String.valueOf(obj.getClass().getMethod("getAgeGroup").invoke(obj));
                  g = String.valueOf(obj.getClass().getMethod("getGender").invoke(obj));
                  reg = String.valueOf(obj.getClass().getMethod("getRegion").invoke(obj));
                  totalSpending = String.valueOf(obj.getClass().getMethod("getTotalSpendingDisplay").invoke(obj)); // "₩31,764,690" 같은 문자열
                  spendingType = String.valueOf(obj.getClass().getMethod("getSpendingType").invoke(obj));
                } catch (Exception ignore) {
                  // Map 방식
                  if (obj instanceof Map) {
                    Map m = (Map) obj;
                    customerId = String.valueOf(m.getOrDefault("customerId", ""));
                    r = String.valueOf(m.getOrDefault("memberRank", ""));
                    ageGroup = String.valueOf(m.getOrDefault("ageGroup", ""));
                    g = String.valueOf(m.getOrDefault("gender", ""));
                    reg = String.valueOf(m.getOrDefault("region", ""));
                    totalSpending = String.valueOf(m.getOrDefault("totalSpendingDisplay", ""));
                    spendingType = String.valueOf(m.getOrDefault("spendingType", ""));
                  }
                }

                String rankClass = "rank-platinum";
                if ("GOLD".equalsIgnoreCase(r)) rankClass = "rank-gold";
                else if ("VIP".equalsIgnoreCase(r)) rankClass = "rank-vip";
                else if ("VVIP".equalsIgnoreCase(r) || "VVip".equalsIgnoreCase(r)) rankClass = "rank-vvip";

                String genderLabel = g;
                if ("M".equalsIgnoreCase(g)) genderLabel = "Male";
                else if ("F".equalsIgnoreCase(g)) genderLabel = "Female";

                String detailUrl = ctx + "/customers/detail?seq=" + customerId;
          %>
            <tr>
              <td class="id"><%= customerId %></td>
              <td><span class="badge <%= rankClass %>"><%= r %></span></td>
              <td><%= ageGroup %></td>
              <td><%= genderLabel %></td>
              <td><%= reg %></td>
              <td style="font-weight:800;"><%= totalSpending %></td>
              <td><span class="chip"><%= spendingType %></span></td>
              <td style="text-align:center;">
                <a class="action" href="<%= detailUrl %>" aria-label="Go to detail">
                  <svg viewBox="0 0 24 24" fill="none">
                    <path d="M10 17l5-5-5-5" stroke="currentColor" stroke-width="2"
                          stroke-linecap="round" stroke-linejoin="round"/>
                  </svg>
                </a>
              </td>
            </tr>
          <%
              }
            }
          %>
        </tbody>
      </table>

      <!-- Pagination (간단 버전) -->
      <div class="pagination">
        <%
          // totalCount 기반으로 총 페이지 계산
          int totalPages = (pageSize == 0) ? 1 : (int) Math.ceil(totalCount / (double) pageSize);

          // 쿼리 스트링 유지(필터 유지)
          String qs =
            "rank=" + java.net.URLEncoder.encode(rank, "UTF-8") +
            "&age=" + java.net.URLEncoder.encode(age, "UTF-8") +
            "&gender=" + java.net.URLEncoder.encode(gender, "UTF-8") +
            "&region=" + java.net.URLEncoder.encode(region, "UTF-8") +
            "&q=" + java.net.URLEncoder.encode(q, "UTF-8") +
            "&pageSize=" + pageSize;

          int prev = Math.max(1, page - 1);
          int next = Math.min(totalPages, page + 1);
        %>

        <a class="page-link" href="<%= ctx %>/members?<%= qs %>&page=<%= prev %>">&laquo;</a>

        <%
          // 현재 주변 3개만 노출
          int start = Math.max(1, page - 1);
          int end = Math.min(totalPages, page + 1);
          for (int p = start; p <= end; p++) {
        %>
          <a class="page-link <%= (p == page) ? "active" : "" %>"
             href="<%= ctx %>/customers?<%= qs %>&page=<%= p %>"><%= p %></a>
        <%
          }
        %>

        <a class="page-link" href="<%= ctx %>/members?<%= qs %>&page=<%= next %>">&raquo;</a>
      </div>
    </div>
  </div>
</body>
</html>