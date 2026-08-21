# Dùng AI hỗ trợ troubleshoot (áp dụng cho lab này)

Mục tiêu: học cách dùng AI (ChatGPT, Claude, Gemini, Claude Code...) như **đồng nghiệp senior ngồi cạnh**, không phải **oracle trả đáp án**. Hỏi thẳng "lỗi gì, sửa sao" AI sẽ trả lời đúng ngay — nhưng bạn mất luôn phần luyện kỹ năng đọc `show ip ospf neighbor` / `show run` và ghép triệu chứng với nguyên nhân.

## Nguyên tắc

1. **AI thu thập & đối chiếu dữ liệu nhanh hơn bạn — không nghĩ hộ bạn.** Paste output lệnh thật, không mô tả bằng lời.
2. **Không hỏi "lỗi gì" — hỏi "giả thuyết nào khớp dữ liệu này, và lệnh nào loại trừ được chúng".** AI trả lời hướng điều tra, bạn tự chạy lệnh xác minh.
3. **Không mở phần "Lời giải tham khảo" trong README rồi paste cho AI.** Mất tác dụng luyện tập — chỉ mở khi đã bí thật sự và muốn đối chiếu.
4. **Yêu cầu AI giải thích *vì sao*, không chỉ đưa lệnh fix.** Nếu AI đưa lệnh mà không giải thích cơ chế (Hello packet, LSA, vai trò area 0...), hỏi lại "vì sao lệnh này sửa được triệu chứng X".

---

## Bước 0 — Thí nghiệm 2 phút: cho AI đoán khi KHÔNG có dữ liệu

Làm bước này **trước** khi thu thập gì cả. Mở AI và hỏi đúng một câu:

> Mạng OSPF ba area, srv1 không ping được srv2. Nguyên nhân là gì?

Đọc kỹ câu trả lời rồi tự đánh giá:

- AI có **nói thẳng một nguyên nhân** như thể nó biết chắc không?
- Nó có hỏi ngược lại bạn dữ liệu nào không?
- Trong danh sách nó đưa ra, bao nhiêu cái **thực sự áp dụng được** cho topology của bạn — mà nó còn chưa hề nhìn thấy?

👉 **Bài học:** AI **mù bối cảnh**. Nó không thấy sơ đồ, không thấy config, không thấy thiết bị của bạn. Càng ít dữ liệu, nó càng lấp đầy bằng suy đoán — và trình bày suy đoán đó bằng giọng văn tự tin y hệt lúc nó đúng. Toàn bộ phần còn lại của tài liệu này là cách nạp dữ liệu để câu trả lời có giá trị.

---

## Quy trình (lặp vòng hypothesis → verify)

### Bước 1 — Thu thập triệu chứng
Chạy lệnh thật trên các node, copy nguyên output:

```bash
# Triệu chứng gốc
docker exec clab-chaos-ospf-lab-srv1 ping -c 4 10.4.4.10

# Trạng thái adjacency toàn mạng
docker exec clab-chaos-ospf-lab-r1 vtysh -c "show ip ospf neighbor"
docker exec clab-chaos-ospf-lab-r2 vtysh -c "show ip ospf neighbor"
docker exec clab-chaos-ospf-lab-r3 vtysh -c "show ip ospf neighbor"
docker exec clab-chaos-ospf-lab-r4 vtysh -c "show ip ospf neighbor"

# Route học được ở hai đầu
docker exec clab-chaos-ospf-lab-r1 vtysh -c "show ip route ospf"
docker exec clab-chaos-ospf-lab-r4 vtysh -c "show ip route ospf"
```

**Prompt mẫu:**
> Bối cảnh: lab OSPF 3 area trên FRR (vtysh). Topology chuỗi: srv1(10.1.1.10) — r1 — r2 — r3 — r4 — srv2(10.4.4.10).
> Thiết kế: srv1↔r1 và r1↔r2 thuộc area 1; r2↔r3 (10.23.0.0/30) là backbone area 0; r3↔r4 và r4↔srv2 thuộc area 2.
> Triệu chứng: srv1 không ping được srv2.
> Dữ liệu: output `show ip ospf neighbor` của cả 4 router và `show ip route ospf` của r1, r4.
>
> Yêu cầu:
> 1. Dựa trên dữ liệu, cho biết adjacency đứt ở chặng nào.
> 2. Liệt kê 3 giả thuyết giải thích được, xếp theo xác suất từ cao xuống thấp.
> 3. Với mỗi giả thuyết, gợi ý ĐÚNG 1 LỆNH `show` để tôi tự kiểm chứng loại trừ.
> 4. RÀNG BUỘC: CHƯA đưa bất kỳ câu lệnh cấu hình sửa lỗi nào. Đánh dấu `[CẦN XÁC NHẬN]` ở điểm bạn đang giả định.
> ```
> <paste output>
> ```

### Bước 2 — Loại trừ giả thuyết (phần đắt giá nhất của bài)

Khi OSPF không lên neighbor, AI gần như chắc chắn sẽ nêu ra nhóm nguyên nhân kinh điển:

| # | Giả thuyết | Lệnh loại trừ |
| :--- | :--- | :--- |
| 1 | Area ID hai đầu lệch nhau | `show ip ospf interface <if>` hai đầu, so trường `Area` |
| 2 | Subnet/netmask hai đầu lệch | `show ip ospf interface <if>`, so `Internet Address` |
| 3 | Hello/Dead timer lệch | `show ip ospf interface <if>`, so `Timer intervals` |
| 4 | Authentication lệch | `show ip ospf`, so dòng `Area has ... authentication` — lưu ý `show ip ospf interface` **không** in dòng auth khi auth đang tắt |
| 5 | MTU lệch | `show ip ospf interface <if>`, so dòng `MTU ... bytes` (MTU lệch làm kẹt `ExStart/Exchange`) |

**Đúng một trong số đó là nguyên nhân thật.** Việc của bạn không phải tin cái AI xếp đầu bảng — mà là chạy lệnh loại trừ từng cái. Đây chính là kỹ năng chuyển giao được sang mọi sự cố OSPF trên thiết bị thật.

💡 **Mẹo đọc dấu hiệu:** neighbor **không xuất hiện chút nào** → lỗi ở tầng Hello (nhóm 1–4). Neighbor **xuất hiện rồi kẹt** ở `ExStart`/`Exchange` → nghi MTU. Chỉ một quan sát này đã cắt được nửa danh sách.

**Prompt mẫu:**
> Đây là `show ip ospf interface` của hai đầu link nghi ngờ. So sánh từng tham số quyết định việc hình thành adjacency (Area ID, subnet mask, Hello/Dead timer, authentication, MTU) và chỉ ra tham số nào lệch. Giải thích cơ chế trước, đừng đưa lệnh sửa vội.

### Bước 3 — Verify trước khi sửa
Trước khi gõ lệnh fix, tự đối chiếu lại với **thiết kế** ghi trong README: link `10.23.0.0/30` đáng lẽ thuộc area nào? Nếu sửa theo hướng bạn định làm, router đó có còn thoả quy tắc "mọi area phải chạm area 0" không?

### Bước 4 — Đề xuất fix, hiểu rồi mới gõ
**Prompt mẫu:**
> Tôi xác định được r3 khai link backbone sai area. Cho tôi lệnh vtysh để sửa mà không phá các khai báo network khác đang chạy. Giải thích từng dòng lệnh làm gì, và cho biết sau khi sửa thì vai trò của r3 trong OSPF thay đổi thế nào.

Gõ lệnh, xác minh lại bằng `show ip ospf neighbor` — thấy neighbor lên `Full` thì mới qua bước tiếp.

### Bước 5 — Xác nhận đầy đủ, không dừng ở "ping thông"
Adjacency lên chưa chắc route đã lan đủ. Kiểm tra cả ba tầng:

```bash
docker exec clab-chaos-ospf-lab-r2 vtysh -c "show ip ospf neighbor"   # 1. adjacency
docker exec clab-chaos-ospf-lab-r1 vtysh -c "show ip route ospf"      # 2. route có tới 10.4.4.0/24
docker exec clab-chaos-ospf-lab-srv1 ping -c 4 10.4.4.10              # 3. dữ liệu thật đi được
```

---

## Bảng prompt mẫu theo giai đoạn

| Giai đoạn | Việc cần AI làm | Không nên hỏi |
|---|---|---|
| Thu thập triệu chứng | Đọc output, chỉ ra chặng đứt, liệt kê giả thuyết + lệnh loại trừ | "Lỗi gì vậy?" |
| Loại trừ giả thuyết | So sánh tham số hai đầu link, chỉ điểm khác biệt bất thường | "Sửa router nào?" |
| Đề xuất fix | Lệnh sửa + giải thích cơ chế, cảnh báo side-effect | Copy-paste lệnh không hiểu |
| Xác nhận | Gợi ý lệnh verify đủ 3 tầng (adjacency → route → ping) | Dừng ngay sau khi ping thông 1 lần |

## Khi nào thật sự nên xem đáp án
Nếu sau ~30–45 phút tự điều tra + hỏi AI theo quy trình trên mà vẫn bí, mở `<details>` "Lời giải tham khảo" trong [`README.md`](./README.md), đối chiếu với giả thuyết bạn đã có — mục tiêu là hiểu *tại sao mình miss*, không phải chỉ copy lệnh sửa.

---
*Kịch bản lab phỏng theo [thangphan205/containerlab-demo — 18-troubleshooting-chaos-lab](https://github.com/thangphan205/containerlab-demo/tree/main/bai-tap-ve-nha/18-troubleshooting-chaos-lab).*
