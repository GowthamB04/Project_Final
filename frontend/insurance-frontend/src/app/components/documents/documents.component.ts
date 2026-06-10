import { Component, OnInit, ChangeDetectorRef } from '@angular/core'; // 1. Imported ChangeDetectorRef
import { CommonModule } from '@angular/common';
import { ApiService } from '../../services/api.service';
import { ClaimService } from '../../services/claim.service';
import { AuthService } from '../../services/auth.service';
import { Claim } from '../../models/claim';
import { Document } from '../../models/document';

@Component({
  selector: 'app-documents',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './documents.component.html',
  styleUrls: ['./documents.component.css'],
})
export class DocumentsComponent implements OnInit {
  documents: Document[] = [];
  approverClaims: Claim[] = [];
  selectedClaim?: Claim;
  loading = true;
  error = '';

  // 2. Injected ChangeDetectorRef (cdr) into the constructor
  constructor(
    private api: ApiService,
    private claimService: ClaimService,
    public auth: AuthService,
    private cdr: ChangeDetectorRef 
  ) {}

  getMimeType(document: Document): string {
    if (!document.documentName) {
      return 'application/octet-stream';
    }
    const extension = document.documentName.split('.').pop()?.toLowerCase();
    switch (extension) {
      case 'pdf':
        return 'application/pdf';
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'gif':
        return 'image/gif';
      default:
        return 'application/octet-stream';
    }
  }

  async createBlobUrl(document: Document): Promise<string | null> {
    if (!document.documentPath) {
      return null;
    }

    const path = document.documentPath.trim();

    if (path.startsWith('data:') || path.startsWith('http') || path.startsWith('/') || path.startsWith('blob:')) {
      return path;
    }

    const mimeType = this.getMimeType(document);
    const dataUrl = path.includes(',') ? path : `data:${mimeType};base64,${path.replace(/\s+/g, '')}`;

    try {
      const resp = await fetch(dataUrl);
      if (!resp.ok) throw new Error('fetch failed');
      const blob = await resp.blob();
      return URL.createObjectURL(blob);
    } catch (e) {
      try {
        const base64Data = dataUrl.split(',').pop() || '';
        const byteCharacters = atob(base64Data.replace(/\s+/g, ''));
        const byteNumbers = new Array(byteCharacters.length);
        for (let i = 0; i < byteCharacters.length; i++) {
          byteNumbers[i] = byteCharacters.charCodeAt(i);
        }
        const byteArray = new Uint8Array(byteNumbers);
        const blob = new Blob([byteArray], { type: mimeType });
        return URL.createObjectURL(blob);
      } catch (err) {
        return dataUrl;
      }
    }
  }

  async viewDocument(doc: Document): Promise<void> {
    const path = doc.documentPath?.trim() || '';
    let url = '';

    if (path.startsWith('/')) {
      const id = (doc as any).documentId ?? (doc as any).id;
      url = id ? `/api/documents/file/${id}` : path;
    } else if (path.startsWith('http://') || path.startsWith('https://')) {
      url = path;
    } else {
      const created = await this.createBlobUrl(doc);
      if (!created) return;
      url = created;
    }

    const mime = this.getMimeType(doc);
    const encodedUrl = url.replace(/"/g, '%22');

    const win = window.open('', '_blank');
    if (!win) return;

    const viewer = mime === 'application/pdf'
      ? `<embed src="${encodedUrl}" type="${mime}" width="100%" height="100%" />`
      : mime.startsWith('image/')
      ? `<img src="${encodedUrl}" style="max-width:100%;height:auto;display:block;margin:0 auto;"/>`
      : `<a href="${encodedUrl}" target="_blank">Open document</a>`;

    const html = `<!doctype html><html><head><title>${doc.documentName || 'Document'}</title><meta charset="utf-8" /><style>html,body{height:100%;margin:0;background:#111;color:#fff}img,embed{display:block;max-height:100vh;margin:0 auto}</style></head><body>${viewer}</body></html>`;
    win.document.open();
    win.document.write(html);
    win.document.close();
  }

  async downloadDocument(doc: Document): Promise<void> {
    const path = doc.documentPath?.trim() || '';
    if (path.startsWith('/')) {
      const id = (doc as any).documentId ?? (doc as any).id;
      if (id) {
        const anchor = window.document.createElement('a');
        anchor.href = `/api/documents/file/${id}`;
        anchor.download = doc.documentName || 'document';
        window.document.body.appendChild(anchor);
        anchor.click();
        window.document.body.removeChild(anchor);
        return;
      }
      const anchor = window.document.createElement('a');
      anchor.href = path;
      anchor.download = doc.documentName || 'document';
      window.document.body.appendChild(anchor);
      anchor.click();
      window.document.body.removeChild(anchor);
      return;
    }

    if (path.startsWith('http://') || path.startsWith('https://')) {
      const anchor = window.document.createElement('a');
      anchor.href = path;
      anchor.download = doc.documentName || 'document';
      window.document.body.appendChild(anchor);
      anchor.click();
      window.document.body.removeChild(anchor);
      return;
    }

    const url = await this.createBlobUrl(doc);
    if (!url) {
      return;
    }
    const anchor = window.document.createElement('a');
    anchor.href = url;
    anchor.download = doc.documentName || 'document';
    window.document.body.appendChild(anchor);
    anchor.click();
    window.document.body.removeChild(anchor);
    if (!doc.documentPath?.startsWith('data:')) {
      setTimeout(() => URL.revokeObjectURL(url), 1000);
    }
  }

  ngOnInit(): void {
    if (this.auth.role === 'APPROVER' && this.auth.userId) {
      this.loadApproverClaims();
    } else {
      this.loadPolicyholderDocuments();
    }
  }

  loadPolicyholderDocuments(): void {
    this.loading = true;
    this.error = '';
    const userId = Number(this.auth.userId);
    if (!userId) {
      this.error = 'Unable to determine user for documents.';
      this.documents = [];
      this.loading = false;
      this.cdr.detectChanges(); // Refresh on error boundary
      return;
    }

    this.api.get<any>(`/documents/user/${userId}`).subscribe({
      next: (result) => {
        if (!result?.status) {
          this.error = result?.message || 'Unable to load documents.';
          this.documents = [];
        } else {
          this.documents = Array.isArray(result.data) ? result.data : [];
        }
        this.loading = false;
        this.cdr.detectChanges(); // 3. Refresh UI instantly when user docs load
      },
      error: () => {
        this.error = 'Unable to load documents.';
        this.loading = false;
        this.cdr.detectChanges(); // Refresh UI on HTTP failure
      },
    });
  }

  loadApproverClaims(): void {
    this.loading = true;
    this.error = '';
    const approverId = Number(this.auth.userId);
    this.claimService.getClaimsByApprover(approverId).subscribe({
      next: (response) => {
        if (!response?.status) {
          this.error = response?.message || 'Unable to load assigned claims.';
          this.loading = false;
          this.cdr.detectChanges(); // Refresh on layout errors
          return;
        }
        this.approverClaims = Array.isArray(response.data) ? response.data : [];
        this.selectedClaim = this.approverClaims.length ? this.approverClaims[0] : undefined;
        this.loading = false;
        this.cdr.detectChanges(); // 4. Refresh UI instantly when approver claims arrive
      },
      error: () => {
        this.error = 'Unable to load assigned claims.';
        this.loading = false;
        this.cdr.detectChanges(); // Refresh UI on HTTP failure
      },
    });
  }

  onClaimChange(event: Event): void {
    const select = event.target as HTMLSelectElement | null;
    const claimId = select?.value ?? '';
    this.selectedClaim = this.approverClaims.find((claim) => String(claim.claimId) === claimId);
    this.cdr.detectChanges(); // 5. Refresh view instantly when dropdown changes manually
  }

  get selectedDocuments(): Document[] {
    return this.selectedClaim?.documents ?? [];
  }
}