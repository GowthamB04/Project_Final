import { Component, OnInit, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { finalize } from 'rxjs/operators';
import { ApiService } from '../../services/api.service';
import { AuthService } from '../../services/auth.service';

@Component({
  selector: 'app-analytics',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './analytics.component.html',
  styleUrls: ['./analytics.component.css'],
})
export class AnalyticsComponent implements OnInit {
  role: string | null = null;
  analytics: any = null;
  isLoading = true;
  errorMessage = '';

  constructor(
    private auth: AuthService,
    private api: ApiService,
    private cdr: ChangeDetectorRef
  ) {}

  ngOnInit(): void {
    this.role = this.auth.role;
    this.loadAnalytics();
  }

  loadAnalytics(): void {
    this.isLoading = true;
    this.analytics = null;
    this.errorMessage = '';

    this.api
      .get<any>('/admin/analytics/overview')
      .pipe(
        finalize(() => {
          this.isLoading = false;
          this.cdr.detectChanges();
        })
      )
      .subscribe({
        next: (response) => {
          if (!response?.status) {
            this.errorMessage =
              response?.message || 'Unable to load analytics summary.';
            return;
          }

          this.analytics = response?.data || {};
          this.cdr.detectChanges();
        },
        error: () => {
          this.errorMessage =
            'Unable to load analytics summary. Please try again later.';
          this.cdr.detectChanges();
        },
      });
  }

  get heading(): string {
    return this.role === 'ADMIN' ? 'Admin Analytics' : 'Analytics';
  }

  private safeNumber(value: any): number {
    const parsed = Number(value);
    return Number.isFinite(parsed) ? parsed : 0;
  }

  get totalClaims(): number {
    return this.safeNumber(this.analytics?.totalClaims);
  }

  get pendingClaims(): number {
    return this.safeNumber(this.analytics?.totalPendingClaims);
  }

  get rejectedClaims(): number {
    return this.safeNumber(this.analytics?.totalRejectedClaims);
  }

  // ✅ SUCCESS = APPROVED + SETTLED
  get successfulClaims(): number {
    return (
      this.safeNumber(this.analytics?.totalApprovedClaims) +
      this.safeNumber(this.analytics?.totalSettledClaims)
    );
  }

  // ✅ REQUESTED AMOUNT
  get totalRequestedAmount(): number {
    return this.safeNumber(this.analytics?.totalRequestedAmount);
  }

  // ✅ PAID AMOUNT
  get totalPaidAmount(): number {
    return this.safeNumber(this.analytics?.totalPaidAmount);
  }

  get claimPercentages(): {
    success: number;
    pending: number;
    rejected: number;
  } {
    const total =
      this.totalClaims ||
      this.successfulClaims +
        this.pendingClaims +
        this.rejectedClaims;

    if (!total) {
      return { success: 0, pending: 0, rejected: 0 };
    }

    return {
      success: (this.successfulClaims / total) * 100,
      pending: (this.pendingClaims / total) * 100,
      rejected: (this.rejectedClaims / total) * 100,
    };
  }

  get pieGradient(): string {
    const { success, pending, rejected } = this.claimPercentages;

    const successEnd = success;
    const pendingEnd = successEnd + pending;

    return `conic-gradient(
      #22c55e 0 ${successEnd}%,
      #f59e0b ${successEnd}% ${pendingEnd}%,
      #ef4444 ${pendingEnd}% 100%
    )`;
  }

  // ✅ BAR WIDTH FIX
  private percent(value: number): number {
    const total = this.totalRequestedAmount + this.totalPaidAmount;
    if (!total) return 0;
    return (value / total) * 100;
  }

  get requestedAmountWidth(): number {
    return this.percent(this.totalRequestedAmount);
  }

  get paidAmountWidth(): number {
    return this.percent(this.totalPaidAmount);
  }
}
