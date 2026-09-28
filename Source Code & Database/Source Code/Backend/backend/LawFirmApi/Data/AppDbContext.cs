using LawFirmApi.Models;
using Microsoft.EntityFrameworkCore;

namespace LawFirmApi.Data;

public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

    public DbSet<User> Users => Set<User>();
    public DbSet<Client> Clients => Set<Client>();
    public DbSet<Lawyer> Lawyers => Set<Lawyer>();
    public DbSet<PracticeArea> PracticeAreas => Set<PracticeArea>();
    public DbSet<LawyerPracticeArea> LawyerPracticeAreas => Set<LawyerPracticeArea>();
    public DbSet<Case> Cases => Set<Case>();
    public DbSet<CaseEvent> CaseEvents => Set<CaseEvent>();
    public DbSet<CaseDocument> CaseDocuments => Set<CaseDocument>();
    public DbSet<Appointment> Appointments => Set<Appointment>();
    public DbSet<Conversation> Conversations => Set<Conversation>();
    public DbSet<Message> Messages => Set<Message>();
    public DbSet<Review> Reviews => Set<Review>();
    public DbSet<Notification> Notifications => Set<Notification>();
    public DbSet<LegalService> LegalServices => Set<LegalService>();
    public DbSet<ConsultationRequest> ConsultationRequests => Set<ConsultationRequest>();
    public DbSet<FavoriteLawyer> FavoriteLawyers => Set<FavoriteLawyer>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        // ---- Users ----
        modelBuilder.Entity<User>(e =>
        {
            e.HasIndex(u => u.Email).IsUnique();
            e.HasIndex(u => u.Phone).IsUnique();
            e.Property(u => u.Role).HasMaxLength(20);
            e.HasCheckConstraint("CK_Users_Role", "[Role] IN ('client','lawyer','staff','admin')");
        });

        // ---- Client 1-1 User ----
        modelBuilder.Entity<Client>(e =>
        {
            e.HasOne(c => c.User).WithOne(u => u.Client)
                .HasForeignKey<Client>(c => c.Id).OnDelete(DeleteBehavior.Cascade);
        });

        // ---- Lawyer 1-1 User ----
        modelBuilder.Entity<Lawyer>(e =>
        {
            e.HasOne(l => l.User).WithOne(u => u.Lawyer)
                .HasForeignKey<Lawyer>(l => l.Id).OnDelete(DeleteBehavior.Cascade);
            e.HasIndex(l => l.BarLicenseNo).IsUnique();
            e.Property(l => l.RatingAvg).HasColumnType("decimal(2,1)");
        });

        // ---- PracticeArea ----
        modelBuilder.Entity<PracticeArea>(e => e.HasIndex(p => p.Name).IsUnique());

        // ---- LawyerPracticeArea (N-N) ----
        modelBuilder.Entity<LawyerPracticeArea>(e =>
        {
            e.HasKey(lpa => new { lpa.LawyerId, lpa.PracticeAreaId });
            e.HasOne(lpa => lpa.Lawyer).WithMany(l => l.LawyerPracticeAreas)
                .HasForeignKey(lpa => lpa.LawyerId).OnDelete(DeleteBehavior.Cascade);
            e.HasOne(lpa => lpa.PracticeArea).WithMany(p => p.LawyerPracticeAreas)
                .HasForeignKey(lpa => lpa.PracticeAreaId).OnDelete(DeleteBehavior.Restrict);
        });

        // ---- Case ----
        modelBuilder.Entity<Case>(e =>
        {
            e.HasIndex(c => c.DocketNo).IsUnique();
            e.HasCheckConstraint("CK_Cases_Status", "[Status] IN ('filed','in_review','hearing','resolved')");
            e.HasOne(c => c.Client).WithMany(cl => cl.Cases)
                .HasForeignKey(c => c.ClientId).OnDelete(DeleteBehavior.Restrict);
            e.HasOne(c => c.Lawyer).WithMany(l => l.Cases)
                .HasForeignKey(c => c.LawyerId).OnDelete(DeleteBehavior.Restrict);
            e.HasOne(c => c.PracticeArea).WithMany()
                .HasForeignKey(c => c.PracticeAreaId).OnDelete(DeleteBehavior.Restrict);
        });

        // ---- CaseEvent ----
        modelBuilder.Entity<CaseEvent>(e =>
        {
            e.HasOne(ev => ev.Case).WithMany(c => c.Events)
                .HasForeignKey(ev => ev.CaseId).OnDelete(DeleteBehavior.Cascade);
        });

        // ---- CaseDocument ----
        modelBuilder.Entity<CaseDocument>(e =>
        {
            e.HasOne(d => d.Case).WithMany(c => c.Documents)
                .HasForeignKey(d => d.CaseId).OnDelete(DeleteBehavior.Cascade);
        });

        // ---- Appointment ----
        modelBuilder.Entity<Appointment>(e =>
        {
            e.HasCheckConstraint("CK_Appointments_Status", "[Status] IN ('pending','confirmed','completed','cancelled')");
            e.HasOne(a => a.Client).WithMany(c => c.Appointments)
                .HasForeignKey(a => a.ClientId).OnDelete(DeleteBehavior.Cascade);
            e.HasOne(a => a.Lawyer).WithMany()
                .HasForeignKey(a => a.LawyerId).OnDelete(DeleteBehavior.Restrict);
            e.HasOne(a => a.Case).WithMany()
                .HasForeignKey(a => a.CaseId).OnDelete(DeleteBehavior.SetNull);
        });

        // ---- Conversation ----
        modelBuilder.Entity<Conversation>(e =>
        {
            e.HasIndex(c => new { c.ClientId, c.LawyerId, c.CaseId }).IsUnique();
            e.HasOne(c => c.Client).WithMany()
                .HasForeignKey(c => c.ClientId).OnDelete(DeleteBehavior.Cascade);
            e.HasOne(c => c.Lawyer).WithMany()
                .HasForeignKey(c => c.LawyerId).OnDelete(DeleteBehavior.Restrict);
        });

        // ---- Message ----
        modelBuilder.Entity<Message>(e =>
        {
            e.HasOne(m => m.Conversation).WithMany(c => c.Messages)
                .HasForeignKey(m => m.ConversationId).OnDelete(DeleteBehavior.Cascade);
        });

        // ---- Review ----
        modelBuilder.Entity<Review>(e =>
        {
            e.HasIndex(r => new { r.ClientId, r.CaseId }).IsUnique();
            e.HasOne(r => r.Lawyer).WithMany()
                .HasForeignKey(r => r.LawyerId).OnDelete(DeleteBehavior.Restrict);
            e.HasOne(r => r.Client).WithMany()
                .HasForeignKey(r => r.ClientId).OnDelete(DeleteBehavior.Restrict);
        });

        // ---- Notification ----
        modelBuilder.Entity<Notification>(e =>
        {
            e.HasCheckConstraint("CK_Notifications_Type", "[Type] IN ('case_update','appointment','message','system')");
            e.HasOne(n => n.User).WithMany()
                .HasForeignKey(n => n.UserId).OnDelete(DeleteBehavior.Cascade);
        });

        // ---- LegalService ----
        modelBuilder.Entity<LegalService>(e =>
        {
            e.HasIndex(s => new { s.PracticeAreaId, s.SortOrder });
            e.Property(s => s.StartingPrice).HasColumnType("decimal(18,2)");
            e.HasOne(s => s.PracticeArea).WithMany().HasForeignKey(s => s.PracticeAreaId).OnDelete(DeleteBehavior.Restrict);
        });

        // ---- ConsultationRequest ----
        // ---- ConsultationRequest ----
        modelBuilder.Entity<ConsultationRequest>(e =>
        {
            e.HasIndex(r => new { r.Status, r.CreatedAt });

            e.HasIndex(r => r.ClientId);

            e.HasIndex(r => r.LawyerId);

            e.HasCheckConstraint(
                "CK_ConsultationRequests_Status",
                "[Status] IN ('new','processing','completed','cancelled')"
            );

            e.HasCheckConstraint(
                "CK_ConsultationRequests_Priority",
                "[Priority] IN ('low','normal','high','urgent')"
            );

            e.HasOne(r => r.Client)
                .WithMany()
                .HasForeignKey(r => r.ClientId)
                .OnDelete(DeleteBehavior.Cascade);

            e.HasOne(r => r.PracticeArea)
                .WithMany()
                .HasForeignKey(r => r.PracticeAreaId)
                .OnDelete(DeleteBehavior.Restrict);

            e.HasOne(r => r.Lawyer)
                .WithMany()
                .HasForeignKey(r => r.LawyerId)
                .OnDelete(DeleteBehavior.NoAction);

            e.HasOne(r => r.Case)
                .WithMany()
                .HasForeignKey(r => r.CaseId)
                .OnDelete(DeleteBehavior.SetNull);
        });

        // ---- FavoriteLawyer ----
        modelBuilder.Entity<FavoriteLawyer>(e =>
        {
            e.HasKey(f => new { f.ClientId, f.LawyerId });
            e.HasOne(f => f.Client).WithMany().HasForeignKey(f => f.ClientId).OnDelete(DeleteBehavior.Cascade);
            e.HasOne(f => f.Lawyer).WithMany().HasForeignKey(f => f.LawyerId).OnDelete(DeleteBehavior.Restrict);
        });

        // ---- Seed dữ liệu lĩnh vực hành nghề ----
        modelBuilder.Entity<PracticeArea>().HasData(
            new PracticeArea { Id = 1, Name = "Hình sự", IconKey = "gavel", SortOrder = 1 },
            new PracticeArea { Id = 2, Name = "Dân sự", IconKey = "balance", SortOrder = 2 },
            new PracticeArea { Id = 3, Name = "Doanh nghiệp", IconKey = "apartment", SortOrder = 3 },
            new PracticeArea { Id = 4, Name = "Hôn nhân", IconKey = "family_restroom", SortOrder = 4 },
            new PracticeArea { Id = 5, Name = "Đất đai", IconKey = "landscape", SortOrder = 5 }
        );

        modelBuilder.Entity<LegalService>().HasData(
            new LegalService { Id = 1, PracticeAreaId = 1, Title = "Tư vấn pháp luật hình sự", Description = "Tư vấn và hỗ trợ các vấn đề pháp luật hình sự.", Detail = "Tư vấn quy định pháp luật, quyền và nghĩa vụ của đương sự, hỗ trợ chuẩn bị hồ sơ.", StartingPrice = 500000, IconKey = "gavel", SortOrder = 1 },
            new LegalService { Id = 2, PracticeAreaId = 2, Title = "Tư vấn pháp luật dân sự", Description = "Giải quyết tranh chấp và giao dịch dân sự.", Detail = "Tư vấn hợp đồng, bồi thường, thừa kế và các tranh chấp dân sự.", StartingPrice = 400000, IconKey = "balance", SortOrder = 2 },
            new LegalService { Id = 3, PracticeAreaId = 3, Title = "Tư vấn doanh nghiệp", Description = "Đồng hành cùng doanh nghiệp trong mọi vấn đề pháp lý.", Detail = "Thành lập doanh nghiệp, hợp đồng, đầu tư và tranh chấp kinh doanh.", StartingPrice = 600000, IconKey = "apartment", SortOrder = 3 },
            new LegalService { Id = 4, PracticeAreaId = 4, Title = "Tư vấn hôn nhân & gia đình", Description = "Tư vấn ly hôn, nuôi con và tài sản.", Detail = "Hỗ trợ thủ tục ly hôn, tranh chấp quyền nuôi con và chia tài sản.", StartingPrice = 500000, IconKey = "family_restroom", SortOrder = 4 },
            new LegalService { Id = 5, PracticeAreaId = 5, Title = "Tư vấn đất đai", Description = "Tư vấn tranh chấp và thủ tục về đất đai.", Detail = "Tranh chấp đất đai, cấp giấy chứng nhận, chuyển nhượng và thừa kế đất.", StartingPrice = 700000, IconKey = "landscape", SortOrder = 5 }
        );
    }
}
