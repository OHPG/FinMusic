import { preferences } from "@kit.ArkData"

/**
 * @Author peerless2012
 * @Email peerless2012@126.com
 * @DateTime 2024/11/9 18:36
 * @Version V1.0
 * @Description
 */
export class AppPrefer {

  public static readonly PREFER = "prefer"

  private static readonly KEY_PRIVACY_GRANT = "privacy_grant"

  private static readonly KEY_CACHE_ENABLED = "cache_enabled"

  private static readonly KEY_CACHE_MAX_SIZE_MB = "cache_max_size_mb"

  private static readonly KEY_CACHE_MAX_COUNT = "cache_max_count"

  private static readonly KEY_DNS_CACHE_ENABLED = "dns_cache_enabled"

  /** 默认缓存上限 512MB */
  public static readonly DEFAULT_CACHE_MAX_SIZE_MB: number = 512

  /** 默认缓存文件数量上限 200 */
  public static readonly DEFAULT_CACHE_MAX_COUNT: number = 200

  private readonly preference: preferences.Preferences

  constructor(context: Context) {
    this.preference = preferences.getPreferencesSync(context, { name: "app_prefer" } )
  }

  public isPrivacyGrant(): boolean {
    if (this.preference.hasSync(AppPrefer.KEY_PRIVACY_GRANT)) {
      return this.preference.getSync(AppPrefer.KEY_PRIVACY_GRANT, false) as boolean
    }
    return false
  }

  public setPrivacyGrant(): void {
    this.preference.putSync(AppPrefer.KEY_PRIVACY_GRANT, true)
    this.preference.flush()
  }

  // ─── 缓存相关 ─────────────────────────────────────────────────────────────

  public isCacheEnabled(): boolean {
    return this.preference.getSync(AppPrefer.KEY_CACHE_ENABLED, false) as boolean
  }

  public setCacheEnabled(enabled: boolean): void {
    this.preference.putSync(AppPrefer.KEY_CACHE_ENABLED, enabled)
    this.preference.flush()
  }

  public getCacheMaxSizeMB(): number {
    return this.preference.getSync(AppPrefer.KEY_CACHE_MAX_SIZE_MB, AppPrefer.DEFAULT_CACHE_MAX_SIZE_MB) as number
  }

  public setCacheMaxSizeMB(sizeMB: number): void {
    this.preference.putSync(AppPrefer.KEY_CACHE_MAX_SIZE_MB, sizeMB)
    this.preference.flush()
  }

  public getCacheMaxCount(): number {
    return this.preference.getSync(AppPrefer.KEY_CACHE_MAX_COUNT, AppPrefer.DEFAULT_CACHE_MAX_COUNT) as number
  }

  public setCacheMaxCount(count: number): void {
    this.preference.putSync(AppPrefer.KEY_CACHE_MAX_COUNT, count)
    this.preference.flush()
  }

  // ─── DNS 缓存相关 ──────────────────────────────────────────────────────────

  public isDnsCacheEnabled(): boolean {
    return this.preference.getSync(AppPrefer.KEY_DNS_CACHE_ENABLED, true) as boolean
  }

  public setDnsCacheEnabled(enabled: boolean): void {
    this.preference.putSync(AppPrefer.KEY_DNS_CACHE_ENABLED, enabled)
    this.preference.flush()
  }

}