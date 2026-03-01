<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
  <%@ page import="java.util.*" %>
    <%@ page import="java.text.NumberFormat" %>
      <%@ page import="dev.sample.dto.CustomerDTO" %>

        <% //=====서버에서 넘겨준 데이터 (예상)=====// members: List<MemberSummaryDto> (아래에서는 Map 형태로도 동작하게 작성)
          // totalCount: Integer
          // page: Integer (1-based)
          // pageSize: Integer
          // filters: Map<String, String> ex) rank, age, gender, region, q

            Object membersObj = request.getAttribute("members");
            List
            <?> members = (membersObj instanceof List) ? (List<?>) membersObj : Collections.emptyList();

            Integer totalCountObj = (Integer) request.getAttribute("totalCount");
            int totalCount = (totalCountObj != null) ? totalCountObj : 0;

            Integer pageObj = (Integer) request.getAttribute("page");
            int currentPage = (pageObj != null) ? pageObj : 1;

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

                  int from = totalCount == 0 ? 0 : (currentPage - 1) * pageSize + 1;
                  int to = Math.min(currentPage * pageSize, totalCount);

                  String ctx = request.getContextPath(); // 컨텍스트 경로 대응
                  %>

                  <!DOCTYPE html>
                  <html>

                  <head>
                    <meta charset="UTF-8" />
                    <title>Woori Card Scope</title>
                    <meta name="viewport" content="width=device-width, initial-scale=1" />

                    <style>
                      :root {
                        --bg: #ffffff;
                        --text: #0f172a;
                        /* slate-900 */
                        --muted: #64748b;
                        /* slate-500 */
                        --line: #e5e7eb;
                        /* gray-200 */
                        --card: #ffffff;
                        --chip-bg: #eff6ff;
                        /* blue-50 */
                        --chip-fg: #2563eb;
                        /* blue-600 */
                        --primary: #1e3a8a;
                        /* indigo-900 */
                        --primary-2: #1d4ed8;
                        /* blue-700 */
                        --soft: #f8fafc;
                        /* slate-50 */
                        --shadow: 0 8px 30px rgba(15, 23, 42, 0.06);
                        --radius: 14px;
                      }

                      * {
                        box-sizing: border-box;
                      }

                      body {
                        margin: 0;
                        background: var(--bg);
                        color: var(--text);
                        font-family: ui-sans-serif, system-ui, -apple-system, Segoe UI, Roboto, "Apple SD Gothic Neo", "Noto Sans KR", Arial, "Helvetica Neue", sans-serif;
                      }

                      .container {
                        max-width: 1200px;
                        margin: 0 auto;
                        padding: 34px 22px 60px;
                      }

                      /* Header */
                      .header-top {
                        display: flex;
                        justify-content: space-between;
                        align-items: center;
                        margin-bottom: 20px;
                      }

                      .user-info {
                        font-size: 14px;
                        color: #475569;
                        display: flex;
                        align-items: center;
                        gap: 12px;
                      }

                      .logout-btn {
                        padding: 6px 12px;
                        background: #f1f5f9;
                        border: 1px solid #cbd5e1;
                        border-radius: 6px;
                        color: #334155;
                        text-decoration: none;
                        font-size: 13px;
                        font-weight: 500;
                        transition: background-color 0.2s;
                      }

                      .logout-btn:hover {
                        background: #e2e8f0;
                      }

                      .title {
                        font-size: 44px;
                        font-weight: 800;
                        letter-spacing: -0.02em;
                        color: #1e3a8a;
                        margin: 0;
                      }

                      .subtitle {
                        margin: 10px 0 26px;
                        color: var(--muted);
                        font-size: 16px;
                        line-height: 1.6;
                      }

                      /* Filter card */
                      .filter-card {
                        background: var(--card);
                        border: 1px solid var(--line);
                        border-radius: var(--radius);
                        box-shadow: var(--shadow);
                        padding: 18px 18px 16px;
                      }

                      .filter-grid {
                        display: grid;
                        grid-template-columns: 1.1fr 1.1fr 1fr 1.2fr 1.6fr auto auto;
                        gap: 14px;
                        align-items: end;
                      }

                      .field label {
                        display: block;
                        font-size: 13px;
                        font-weight: 600;
                        color: #334155;
                        margin: 0 0 8px;
                      }

                      .control {
                        width: 100%;
                        height: 44px;
                        border: 1px solid var(--line);
                        border-radius: 12px;
                        padding: 0 12px;
                        background: #f8fafc;
                        color: var(--text);
                        outline: none;
                      }

                      .control:focus {
                        border-color: #c7d2fe;
                        box-shadow: 0 0 0 3px rgba(99, 102, 241, 0.12);
                        background: #ffffff;
                      }

                      .search-wrap {
                        position: relative;
                      }

                      .search-wrap .control {
                        padding-left: 40px;
                      }

                      .search-icon {
                        position: absolute;
                        left: 12px;
                        top: 50%;
                        transform: translateY(-50%);
                        width: 18px;
                        height: 18px;
                        color: #94a3b8;
                      }

                      .btn {
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

                      .btn:hover {
                        background: #f8fafc;
                      }

                      .btn-primary {
                        background: var(--primary);
                        border-color: var(--primary);
                        color: #fff;
                        padding: 0 16px;
                      }

                      .btn-primary:hover {
                        background: #172554;
                      }

                      .btn svg {
                        width: 18px;
                        height: 18px;
                      }

                      .meta {
                        margin: 16px 2px 14px;
                        color: var(--muted);
                        font-size: 14px;
                      }

                      /* Table card */
                      .table-card {
                        margin-top: 10px;
                        background: var(--card);
                        border: 1px solid var(--line);
                        border-radius: var(--radius);
                        box-shadow: var(--shadow);
                        overflow: hidden;
                      }

                      table {
                        width: 100%;
                        border-collapse: separate;
                        border-spacing: 0;
                      }

                      thead th {
                        text-align: left;
                        font-size: 12px;
                        letter-spacing: 0.08em;
                        text-transform: uppercase;
                        color: #64748b;
                        background: #f8fafc;
                        border-bottom: 1px solid var(--line);
                        padding: 16px 16px;
                      }

                      tbody td {
                        padding: 18px 16px;
                        border-bottom: 1px solid #f1f5f9;
                        color: #0f172a;
                        font-size: 15px;
                        vertical-align: middle;
                      }

                      tbody tr:hover {
                        background: #fafafa;
                      }

                      .id {
                        font-weight: 800;
                        letter-spacing: 0.02em;
                      }

                      /* Rank badge */
                      .badge {
                        display: inline-flex;
                        align-items: center;
                        height: 28px;
                        padding: 0 12px;
                        border-radius: 999px;
                        font-size: 13px;
                        font-weight: 800;
                        border: 1px solid transparent;
                      }

                      .rank-gold {
                        color: #b45309;
                        background: #fffbeb;
                        border-color: #fde68a;
                      }

                      .rank-platinum {
                        color: #334155;
                        background: #f1f5f9;
                        border-color: #e2e8f0;
                      }

                      .rank-vip {
                        color: #1d4ed8;
                        background: #eff6ff;
                        border-color: #bfdbfe;
                      }

                      .rank-vvip {
                        color: #0f172a;
                        background: #0f172a;
                        border-color: #0f172a;
                        color: #fff;
                      }

                      /* Spending type chip */
                      .chip {
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
                      .action {
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

                      .action:hover {
                        background: #f8fafc;
                      }

                      .action svg {
                        width: 18px;
                        height: 18px;
                        color: #1e3a8a;
                      }

                      /* Pagination */
                      .pagination {
                        display: flex;
                        justify-content: flex-end;
                        gap: 8px;
                        padding: 14px 16px;
                        background: #fff;
                      }

                      .page-link {
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

                      .page-link:hover {
                        background: #f8fafc;
                      }

                      .page-link.active {
                        background: #eef2ff;
                        border-color: #c7d2fe;
                        color: #1e3a8a;
                      }

                      /* Responsive */
                      @media (max-width: 1100px) {
                        .filter-grid {
                          grid-template-columns: 1fr 1fr;
                        }

                        .btn,
                        .btn-primary {
                          width: 100%;
                          justify-content: center;
                        }
                      }
                    </style>
                  </head>

                  <body>
                    <div class="container">
                      <div class="header-top">
                        <div>
                          <h1 class="title">Woori Card Scope</h1>
                          <div class="subtitle">Member Rank Growth &amp; Spending Insight Analytics Platform</div>
                        </div>
                        <c:if test="${not empty sessionScope.USER}">
                          <div class="user-info">
                            <span><strong>${sessionScope.USER.name}</strong> 님 환영합니다</span>
                            <a href="<%= ctx %>/logout" class="logout-btn">로그아웃</a>
                          </div>
                        </c:if>
                      </div>

                      <!-- Filters -->
                      <form class="filter-card" method="get" action="<%= ctx %>/customers">
                        <div class="filter-grid">
                          <div class="field">
                            <label for="rank">Member Rank</label>
                            <select class="control" id="rank" name="rank">
                              <option value="" <%=rank.isEmpty() ? "selected" : "" %>>All Ranks</option>
                              <option value="24" <%="24" .equals(rank) ? "selected" : "" %>>Gold</option>
                              <option value="23" <%="23" .equals(rank) ? "selected" : "" %>>Platinum</option>
                              <option value="22" <%="22" .equals(rank) ? "selected" : "" %>>VIP</option>
                              <option value="21" <%="21" .equals(rank) ? "selected" : "" %>>VVIP</option>
                            </select>
                          </div>

                          <div class="field">
                            <label for="age">Age Group</label>
                            <select class="control" id="age" name="age">
                              <option value="" <%=age.isEmpty() ? "selected" : "" %>>All Ages</option>
                              <option value="20" <%="20" .equals(age) ? "selected" : "" %>>20대</option>
                              <option value="25" <%="25" .equals(age) ? "selected" : "" %>>25대</option>
                              <option value="30" <%="30" .equals(age) ? "selected" : "" %>>30대</option>
                              <option value="35" <%="35" .equals(age) ? "selected" : "" %>>35대</option>
                              <option value="40" <%="40" .equals(age) ? "selected" : "" %>>40대</option>
                              <option value="45" <%="45" .equals(age) ? "selected" : "" %>>45대</option>
                              <option value="50" <%="50" .equals(age) ? "selected" : "" %>>50대</option>
                              <option value="55" <%="55" .equals(age) ? "selected" : "" %>>55대</option>
                              <option value="60" <%="60" .equals(age) ? "selected" : "" %>>60대</option>
                              <option value="65" <%="65" .equals(age) ? "selected" : "" %>>65대</option>
                              <option value="70" <%="70" .equals(age) ? "selected" : "" %>>70대</option>
                            </select>
                          </div>

                          <div class="field">
                            <label for="gender">Gender</label>
                            <select class="control" id="gender" name="gender">
                              <option value="" <%=gender.isEmpty() ? "selected" : "" %>>All</option>
                              <option value="1" <%="1" .equals(gender) ? "selected" : "" %>>Male</option>
                              <option value="2" <%="2" .equals(gender) ? "selected" : "" %>>Female</option>
                            </select>
                          </div>

                          <div class="field">
                            <label for="region">Region</label>
                            <select class="control" id="region" name="region">
                              <option value="" <%=region.isEmpty() ? "selected" : "" %>>All Regions</option>
                              <option value="서울" <%="서울" .equals(region) ? "selected" : "" %>>서울</option>
                              <option value="경기" <%="경기" .equals(region) ? "selected" : "" %>>경기</option>
                              <option value="인천" <%="인천" .equals(region) ? "selected" : "" %>>인천</option>
                              <option value="부산" <%="부산" .equals(region) ? "selected" : "" %>>부산</option>
                              <option value="대구" <%="대구" .equals(region) ? "selected" : "" %>>대구</option>
                              <option value="광주" <%="광주" .equals(region) ? "selected" : "" %>>광주</option>
                              <option value="대전" <%="대전" .equals(region) ? "selected" : "" %>>대전</option>
                              <option value="울산" <%="울산" .equals(region) ? "selected" : "" %>>울산</option>
                              <option value="세종" <%="세종" .equals(region) ? "selected" : "" %>>세종</option>
                              <option value="강원" <%="강원" .equals(region) ? "selected" : "" %>>강원</option>
                              <option value="충북" <%="충북" .equals(region) ? "selected" : "" %>>충북</option>
                              <option value="충남" <%="충남" .equals(region) ? "selected" : "" %>>충남</option>
                              <option value="전북" <%="전북" .equals(region) ? "selected" : "" %>>전북</option>
                              <option value="전남" <%="전남" .equals(region) ? "selected" : "" %>>전남</option>
                              <option value="경북" <%="경북" .equals(region) ? "selected" : "" %>>경북</option>
                              <option value="경남" <%="경남" .equals(region) ? "selected" : "" %>>경남</option>
                              <option value="제주" <%="제주" .equals(region) ? "selected" : "" %>>제주</option>
                            </select>
                          </div>

                          <div class="field search-wrap">
                            <label for="q">Customer ID</label>
                            <svg class="search-icon" viewBox="0 0 24 24" fill="none" aria-hidden="true">
                              <path d="M21 21l-4.3-4.3m1.8-5.2a7 7 0 11-14 0 7 7 0 0114 0z" stroke="currentColor"
                                stroke-width="2" stroke-linecap="round" stroke-linejoin="round" />
                            </svg>
                            <input class="control" id="q" name="q" value="<%= q %>" placeholder="Search by ID..." />
                          </div>

                          <a class="btn" href="<%= ctx %>/customers">
                            <svg viewBox="0 0 24 24" fill="none" aria-hidden="true">
                              <path d="M4 4v6h6M20 20v-6h-6M20 9a8 8 0 00-14.9-3M4 15a8 8 0 0014.9 3"
                                stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" />
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
                              <th style="width: 120px;">기준년도</th>
                              <th style="width: 160px;">Customer ID</th>
                              <th style="width: 120px;">Member Rank</th>
                              <th style="width: 80px;">Age</th>
                              <th style="width: 80px;">Gender</th>
                              <th style="width: 120px;">Region</th>
                              <th style="width: 160px;">Total Spending</th>
                              <th style="width: 90px; text-align:center;">Action</th>
                            </tr>
                          </thead>

                          <tbody>
                            <% if (members.isEmpty()) { %>
                              <tr>
                                <td colspan="8" style="text-align:center; padding: 28px; color:#64748b;">
                                  No customers found.
                                </td>
                              </tr>
                              <% } else { NumberFormat nf=NumberFormat.getInstance(); java.util.Map<String,String>
                                rankMap = new java.util.HashMap<>();
                                  rankMap.put("21", "VVIP"); rankMap.put("22", "VIP");
                                  rankMap.put("23", "Platinum"); rankMap.put("24", "Gold"); rankMap.put("25", "기타");
                                  for (Object obj : members) {
                                  CustomerDTO.ListAllDTO dto = (CustomerDTO.ListAllDTO) obj;
                                  String customerId = dto.seq();
                                  String rCode = dto.mbrRk() != null ? dto.mbrRk() : "";
                                  String r = rankMap.getOrDefault(rCode, rCode);
                                  String ageGroup = dto.age() != null ? dto.age() : "";
                                  String gCode = dto.sexCd() != null ? dto.sexCd() : "";
                                  String genderLabel = "1".equals(gCode) ? "Male" : "2".equals(gCode) ? "Female" :
                                  gCode;
                                  String reg = dto.housSidoNm() != null ? dto.housSidoNm() : "";
                                  String totalSpending = dto.totUseAm() != null ? nf.format(dto.totUseAm()) + "만원" : "";

                                  String rankClass = "rank-platinum";
                                  if ("24".equals(rCode)) rankClass = "rank-gold";
                                  else if ("22".equals(rCode)) rankClass = "rank-vip";
                                  else if ("21".equals(rCode)) rankClass = "rank-vvip";
                                  String detailUrl = ctx + "/customers/detail?seq=" + customerId;
                                  String basYh = dto.basYh() != null ? dto.basYh() : "";
                                  String basYhDisplay = basYh.length() == 4 ? basYh + "년" : basYh;
                                  %>
                                  <tr>
                                    <td>
                                      <%= basYhDisplay %>
                                    </td>
                                    <td class="id">
                                      <%= customerId %>
                                    </td>
                                    <td><span class="badge <%= rankClass %>">
                                        <%= r %>
                                      </span></td>
                                    <td>
                                      <%= ageGroup %>
                                    </td>
                                    <td>
                                      <%= genderLabel %>
                                    </td>
                                    <td>
                                      <%= reg %>
                                    </td>
                                    <td style="font-weight:800;">
                                      <%= totalSpending %>
                                    </td>
                                    <td style="text-align:center;">
                                      <a class="action" href="<%= detailUrl %>" aria-label="Go to detail">
                                        <svg viewBox="0 0 24 24" fill="none">
                                          <path d="M10 17l5-5-5-5" stroke="currentColor" stroke-width="2"
                                            stroke-linecap="round" stroke-linejoin="round" />
                                        </svg>
                                      </a>
                                    </td>
                                  </tr>
                                  <% } } %>
                          </tbody>
                        </table>

                        <!-- Pagination (간단 버전) -->
                        <div class="pagination">
                          <% int totalPages=(pageSize==0) ? 1 : (int) Math.ceil(totalCount / (double) pageSize); String
                            qs="rank=" + java.net.URLEncoder.encode(rank, "UTF-8" ) + "&age=" +
                            java.net.URLEncoder.encode(age, "UTF-8" ) + "&gender=" +
                            java.net.URLEncoder.encode(gender, "UTF-8" ) + "&region=" +
                            java.net.URLEncoder.encode(region, "UTF-8" ) + "&q=" + java.net.URLEncoder.encode(q, "UTF-8"
                            ) + "&pageSize=" + pageSize; int prev=Math.max(1, currentPage - 1); int
                            next=Math.min(totalPages, currentPage + 1); %>

                            <a class="page-link" href="<%= ctx %>/customers?<%= qs %>&page=<%= prev %>">&laquo;</a>

                            <% int start=Math.max(1, currentPage - 1); int end=Math.min(totalPages, currentPage + 1);
                              for (int p=start; p <=end; p++) { %>
                              <a class="page-link <%= (p == currentPage) ? " active" : "" %>"
                                href="<%= ctx %>/customers?<%= qs %>&page=<%= p %>"><%= p %></a>
                              <% } %>

                                <a class="page-link" href="<%= ctx %>/customers?<%= qs %>&page=<%= next %>">&raquo;</a>
                        </div>
                      </div>
                    </div>
                  </body>

                  </html>