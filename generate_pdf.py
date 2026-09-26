import os
from reportlab.lib.pagesizes import letter
from reportlab.lib import colors
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, HRFlowable, KeepTogether
)
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.pdfgen import canvas

class NumberedCanvas(canvas.Canvas):
    def __init__(self, *args, **kwargs):
        super(NumberedCanvas, self).__init__(*args, **kwargs)
        self._saved_page_states = []

    def showPage(self):
        self._saved_page_states.append(dict(self.__dict__))
        self._startPage()

    def save(self):
        num_pages = len(self._saved_page_states)
        for state in self._saved_page_states:
            self.__dict__.update(state)
            self.draw_page_number(num_pages)
            canvas.Canvas.showPage(self)
        canvas.Canvas.save(self)

    def draw_page_number(self, page_count):
        self.saveState()
        self.setFont("Helvetica", 8)
        self.setFillColor(colors.HexColor("#71717A"))
        
        # Header (pages > 1)
        if self._pageNumber > 1:
            self.drawString(54, 755, "MILESTONE // 12-Month Financial Trajectory & Business Model")
            self.setStrokeColor(colors.HexColor("#27272A"))
            self.setLineWidth(0.5)
            self.line(54, 747, letter[0] - 54, 747)

        # Footer
        page_str = f"Page {self._pageNumber} of {page_count}"
        self.drawRightString(letter[0] - 54, 35, page_str)
        self.drawString(54, 35, "CONFIDENTIAL // INDIE STUDIO PLAYBOOK // MILESTONE APP")
        self.setStrokeColor(colors.HexColor("#27272A"))
        self.setLineWidth(0.5)
        self.line(54, 47, letter[0] - 54, 47)
        self.restoreState()

def build_pdf(filename="Milestone_12Month_Financial_Model.pdf"):
    doc = SimpleDocTemplate(
        filename,
        pagesize=letter,
        leftMargin=54,
        rightMargin=54,
        topMargin=54,
        bottomMargin=54
    )

    styles = getSampleStyleSheet()
    
    # Custom Palette
    c_primary = colors.HexColor("#09090B")      # Pitch Dark
    c_accent = colors.HexColor("#F97316")       # Milestone Warm Amber
    c_zinc_100 = colors.HexColor("#F4F4F5")
    c_zinc_400 = colors.HexColor("#A1A1AA")
    c_zinc_700 = colors.HexColor("#3F3F46")
    c_zinc_800 = colors.HexColor("#27272A")
    c_zinc_900 = colors.HexColor("#18181B")
    c_green = colors.HexColor("#10B981")

    # Typography styles
    title_style = ParagraphStyle(
        'DocTitle',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=24,
        leading=28,
        textColor=colors.HexColor("#09090B")
    )

    subtitle_style = ParagraphStyle(
        'DocSubtitle',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=10,
        leading=14,
        textColor=colors.HexColor("#71717A"),
        spaceAfter=15
    )

    h1_style = ParagraphStyle(
        'SectionH1',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=13,
        leading=17,
        textColor=colors.HexColor("#09090B"),
        spaceBefore=12,
        spaceAfter=6
    )

    body_style = ParagraphStyle(
        'BodyDark',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=9,
        leading=13.5,
        textColor=colors.HexColor("#27272A")
    )

    body_bold = ParagraphStyle(
        'BodyBold',
        parent=body_style,
        fontName='Helvetica-Bold'
    )

    callout_style = ParagraphStyle(
        'CalloutText',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=8.5,
        leading=12.5,
        textColor=colors.HexColor("#18181B")
    )

    table_header = ParagraphStyle(
        'TableHeader',
        parent=styles['Normal'],
        fontName='Helvetica-Bold',
        fontSize=8,
        leading=10,
        textColor=colors.white
    )

    table_cell = ParagraphStyle(
        'TableCell',
        parent=styles['Normal'],
        fontName='Helvetica',
        fontSize=8,
        leading=11,
        textColor=colors.HexColor("#18181B")
    )

    table_cell_bold = ParagraphStyle(
        'TableCellBold',
        parent=table_cell,
        fontName='Helvetica-Bold'
    )

    table_cell_green = ParagraphStyle(
        'TableCellGreen',
        parent=table_cell,
        fontName='Helvetica-Bold',
        textColor=colors.HexColor("#047857")
    )

    story = []

    # 1. Header Banner
    story.append(Paragraph("MILESTONE // 12-MONTH STRATEGY", ParagraphStyle('Eyebrow', fontName='Helvetica-Bold', fontSize=8.5, leading=11, textColor=c_accent, spaceAfter=4)))
    story.append(Paragraph("12-Month Financial Trajectory & Business Model", title_style))
    story.append(Paragraph("The High-Yield Cash Cow & Asset Exit Playbook | Focus: Front-Loaded Revenue, Viral Widget Hook, Zero Maintenance", subtitle_style))
    story.append(HRFlowable(width="100%", thickness=1, color=colors.HexColor("#E4E4E7"), spaceBefore=0, spaceAfter=14))

    # 2. Executive Summary Box
    summary_html = """
    <b>EXECUTIVE THESIS:</b> Milestone is built on zero-marginal-cost architecture (SwiftData, local notifications, widgets) and a hyper-differentiated retro-industrial aesthetic. This business model does <b>not</b> attempt to build a forever SaaS like Todoist or Notion. Instead, it executes an <b>Indie Studio Cash-Cow Cycle</b>: (1) validate ad/organic creative in Month 1, (2) capture a massive front-loaded revenue spike in Month 2–3 via viral TikTok/Reels widget content, (3) harvest steady long-tail search cash, and (4) retain the option to flip the app on Acquire.com for a 2.5x–3.5x net multiple.
    """
    summary_table = Table([[Paragraph(summary_html, callout_style)]], colWidths=[504])
    summary_table.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), colors.HexColor("#F4F4F5")),
        ('LEFTPADDING', (0,0), (-1,-1), 12),
        ('RIGHTPADDING', (0,0), (-1,-1), 12),
        ('TOPPADDING', (0,0), (-1,-1), 10),
        ('BOTTOMPADDING', (0,0), (-1,-1), 10),
        ('LINELEFT', (0,0), (0,-1), 3, c_accent),
        ('BOX', (0,0), (-1,-1), 0.5, colors.HexColor("#E4E4E7")),
    ]))
    story.append(summary_table)
    story.append(Spacer(1, 14))

    # 3. The Business Model: Front-Loaded Monetization
    story.append(Paragraph("1. Monetization Architecture: Front-Loaded Cash Capture", h1_style))
    p1 = """
    Standard productivity apps bleed cash because they rely on $3.99/month subscriptions. In personal productivity, Month 2 churn typically exceeds 80%. If a user churns after 30 days, gross revenue is only $3.99 ($3.39 after Apple's cut), making paid advertising and viral conversion mathematically unprofitable.
    <br/><br/>
    <b>Milestone's Front-Loaded Pricing Matrix:</b>
    """
    story.append(Paragraph(p1, body_style))
    story.append(Spacer(1, 6))

    pricing_data = [
        [Paragraph("Plan Tier", table_header), Paragraph("Price Point", table_header), Paragraph("Share of Sales", table_header), Paragraph("Strategic Objective", table_header)],
        [Paragraph("<b>Annual (Trial)</b>", table_cell), Paragraph("<b>$29.99 - $39.99</b> / yr", table_cell_bold), Paragraph("65%", table_cell), Paragraph("Primary target. 3-day trial onboards impulse buyers; upfront annual payout eliminates churn risk.", table_cell)],
        [Paragraph("<b>Lifetime Pass</b>", table_cell), Paragraph("<b>$49.99 - $59.99</b> once", table_cell_bold), Paragraph("20%", table_cell), Paragraph("Appeals to subscription-averse power users; immediate $42.50 net cash injection per checkout.", table_cell)],
        [Paragraph("<b>Weekly (Ad Funnel)</b>", table_cell), Paragraph("<b>$3.99 - $4.99</b> / wk", table_cell_bold), Paragraph("15%", table_cell), Paragraph("Optimized for paid TikTok/Meta traffic where users impulse-buy; yields $16-$20 before cancellation.", table_cell)],
    ]
    pricing_table = Table(pricing_data, colWidths=[90, 85, 65, 264])
    pricing_table.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), c_zinc_900),
        ('GRID', (0,0), (-1,-1), 0.5, colors.HexColor("#E4E4E7")),
        ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.white, colors.HexColor("#FAFAFA")]),
        ('TOPPADDING', (0,0), (-1,-1), 6),
        ('BOTTOMPADDING', (0,0), (-1,-1), 6),
        ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
    ]))
    story.append(pricing_table)
    story.append(Spacer(1, 14))

    # 4. Financial Trajectory Table (12 Months)
    story.append(Paragraph("2. 12-Month Financial Trajectory (Viral Breakthrough Scenario)", h1_style))
    p2 = """
    Based on organic aesthetic short-form distribution (TikTok/Reels) in Month 2 paired with $25k total reinvested paid spend, decaying to an organic ASO baseline:
    """
    story.append(Paragraph(p2, body_style))
    story.append(Spacer(1, 6))

    fin_data = [
        [
            Paragraph("Month", table_header),
            Paragraph("Phase / Event", table_header),
            Paragraph("Installs", table_header),
            Paragraph("Conv %", table_header),
            Paragraph("Gross Rev", table_header),
            Paragraph("Apple (15%)", table_header),
            Paragraph("Ad / Cost", table_header),
            Paragraph("Net Cash", table_header)
        ],
        [Paragraph("M01", table_cell), Paragraph("Soft Launch & Ad Creative Test", table_cell), Paragraph("2,800", table_cell), Paragraph("2.5%", table_cell), Paragraph("$2,450", table_cell), Paragraph("-$367", table_cell), Paragraph("-$500", table_cell), Paragraph("$1,583", table_cell_green)],
        [Paragraph("M02", table_cell_bold), Paragraph("<b>Viral Spike (Reels/TikTok/Ads)</b>", table_cell), Paragraph("<b>120,000</b>", table_cell_bold), Paragraph("3.8%", table_cell), Paragraph("<b>$159,600</b>", table_cell_bold), Paragraph("-$23,940", table_cell), Paragraph("-$18,000", table_cell), Paragraph("<b>$117,660</b>", table_cell_green)],
        [Paragraph("M03", table_cell), Paragraph("Viral Afterglow & Algorithmic Lift", table_cell), Paragraph("38,000", table_cell), Paragraph("3.2%", table_cell), Paragraph("$42,560", table_cell), Paragraph("-$6,384", table_cell), Paragraph("-$6,500", table_cell), Paragraph("$29,676", table_cell_green)],
        [Paragraph("M04", table_cell), Paragraph("Organic Decay & Feature Influx", table_cell), Paragraph("14,000", table_cell), Paragraph("2.9%", table_cell), Paragraph("$14,210", table_cell), Paragraph("-$2,131", table_cell), Paragraph("-$1,000", table_cell), Paragraph("$11,079", table_cell_green)],
        [Paragraph("M05", table_cell), Paragraph("Transition to Baseline", table_cell), Paragraph("8,500", table_cell), Paragraph("2.7%", table_cell), Paragraph("$8,032", table_cell), Paragraph("-$1,205", table_cell), Paragraph("-$500", table_cell), Paragraph("$6,327", table_cell_green)],
        [Paragraph("M06", table_cell), Paragraph("Steady-State ASO Search", table_cell), Paragraph("6,000", table_cell), Paragraph("2.6%", table_cell), Paragraph("$5,460", table_cell), Paragraph("-$819", table_cell), Paragraph("$0", table_cell), Paragraph("$4,641", table_cell_green)],
        [Paragraph("M07", table_cell), Paragraph("Long-Tail Search & Backlinks", table_cell), Paragraph("4,500", table_cell), Paragraph("2.5%", table_cell), Paragraph("$3,937", table_cell), Paragraph("-$590", table_cell), Paragraph("$0", table_cell), Paragraph("$3,347", table_cell_green)],
        [Paragraph("M08", table_cell), Paragraph("Long-Tail Autopilot", table_cell), Paragraph("4,000", table_cell), Paragraph("2.5%", table_cell), Paragraph("$3,500", table_cell), Paragraph("-$525", table_cell), Paragraph("$0", table_cell), Paragraph("$2,975", table_cell_green)],
        [Paragraph("M09", table_cell), Paragraph("Long-Tail Autopilot", table_cell), Paragraph("3,600", table_cell), Paragraph("2.5%", table_cell), Paragraph("$3,150", table_cell), Paragraph("-$472", table_cell), Paragraph("$0", table_cell), Paragraph("$2,678", table_cell_green)],
        [Paragraph("M10", table_cell), Paragraph("Long-Tail Autopilot", table_cell), Paragraph("3,300", table_cell), Paragraph("2.5%", table_cell), Paragraph("$2,887", table_cell), Paragraph("-$433", table_cell), Paragraph("$0", table_cell), Paragraph("$2,454", table_cell_green)],
        [Paragraph("M11", table_cell), Paragraph("Long-Tail Autopilot", table_cell), Paragraph("3,100", table_cell), Paragraph("2.4%", table_cell), Paragraph("$2,604", table_cell), Paragraph("-$391", table_cell), Paragraph("$0", table_cell), Paragraph("$2,213", table_cell_green)],
        [Paragraph("M12", table_cell), Paragraph("Long-Tail + First Year Renewals", table_cell), Paragraph("3,000", table_cell), Paragraph("2.5%", table_cell), Paragraph("$6,200", table_cell), Paragraph("-$930", table_cell), Paragraph("$0", table_cell), Paragraph("$5,270", table_cell_green)],
        [Paragraph("<b>TOTALS</b>", table_cell_bold), Paragraph("<b>Year 1 Performance</b>", table_cell_bold), Paragraph("<b>210,800</b>", table_cell_bold), Paragraph("<b>3.1% avg</b>", table_cell_bold), Paragraph("<b>$254,590</b>", table_cell_bold), Paragraph("<b>-$38,187</b>", table_cell_bold), Paragraph("<b>-$26,500</b>", table_cell_bold), Paragraph("<b>$189,903</b>", table_cell_green)]
    ]
    fin_table = Table(fin_data, colWidths=[36, 140, 48, 44, 58, 58, 52, 68])
    fin_table.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,0), c_zinc_900),
        ('GRID', (0,0), (-1,-1), 0.5, colors.HexColor("#E4E4E7")),
        ('ROWBACKGROUNDS', (0,1), (-1,-2), [colors.white, colors.HexColor("#FAFAFA")]),
        ('BACKGROUND', (0,-1), (-1,-1), colors.HexColor("#F4F4F5")),
        ('TOPPADDING', (0,0), (-1,-1), 4),
        ('BOTTOMPADDING', (0,0), (-1,-1), 4),
        ('ALIGN', (2,0), (-1,-1), 'RIGHT'),
        ('VALIGN', (0,0), (-1,-1), 'MIDDLE'),
    ]))
    story.append(fin_table)
    story.append(Spacer(1, 14))

    # 5. Core Growth Pillars
    story.append(Paragraph("3. Customer Acquisition & Viral Distribution Mechanics", h1_style))
    pillars_html = """
    • <b>Visual Hardware Positioning:</b> The app is not sold as a to-do list; it is marketed as an <i>aesthetic status symbol</i> for iOS homescreens. Videos feature clean minimalist desk setups showcasing the <b>Dual-Pillar Dot Matrix Widget</b> and Dynamic Island Live Activities.<br/>
    • <b>The Viral Ad Loop:</b> Run 5-10 organic variations on TikTok/Instagram Reels. When a creative organically exceeds 40k views, immediately convert it to a <b>TikTok Spark Ad</b>, putting $100-$300/day behind it while maintaining a Return on Ad Spend (ROAS) of 2.2x.<br/>
    • <b>ASO Keywords:</b> Maximize keyword metadata for: <i>single task tracker, dot matrix widget, focus timer aesthetic, daily highlight app, dual pillar</i>.
    """
    story.append(Paragraph(pillars_html, body_style))
    story.append(Spacer(1, 14))

    # 6. Year-End Asset Exit Strategy
    exit_html = """
    <b>MONTH 12 EXIT OPPORTUNITY (ACQUIRE.COM):</b><br/>
    Because Milestone runs with zero server infrastructure, trailing 12-month net margins exceed <b>74%</b>. At an annual net profit of <b>~$190,000</b> and consistent $2,500/mo autopilot revenue, the app qualifies as an institutional-grade micro-acquisition target.
    <br/><br/>
    • <b>Target Multiplier:</b> 2.5x to 3.5x Trailing Net Profit.<br/>
    • <b>Potential Lump-Sum Exit Value:</b> <b>$475,000 – $665,000</b>.<br/>
    • <b>Combined 1-Year Financial Return:</b> <b>$660,000+</b> (Net Operating Cash + Asset Sale).
    """
    exit_table = Table([[Paragraph(exit_html, callout_style)]], colWidths=[504])
    exit_table.setStyle(TableStyle([
        ('BACKGROUND', (0,0), (-1,-1), colors.HexColor("#F0FDF4")),
        ('LEFTPADDING', (0,0), (-1,-1), 12),
        ('RIGHTPADDING', (0,0), (-1,-1), 12),
        ('TOPPADDING', (0,0), (-1,-1), 10),
        ('BOTTOMPADDING', (0,0), (-1,-1), 10),
        ('LINELEFT', (0,0), (0,-1), 3, c_green),
        ('BOX', (0,0), (-1,-1), 0.5, colors.HexColor("#BBF7D0")),
    ]))
    story.append(exit_table)

    doc.build(story, canvasmaker=NumberedCanvas)
    print(f"Successfully generated {filename}")

if __name__ == "__main__":
    build_pdf()
