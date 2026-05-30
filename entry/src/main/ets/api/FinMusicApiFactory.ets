import { JellyfinFinApi } from "./jellyfin/JellyfinFinApi";
import { ApiFactory, CoreApi, ServerType } from "@ohpg/fin-core";

/**
 * @Author peerless2012
 * @Email peerless2012@126.com
 * @DateTime 2025/5/30 12:00
 * @Version V1.0
 * @Description
 */
export class FinMusicApiFactory extends ApiFactory {

  constructor(context: Context) {
    super(context, "FinMusic")
  }

  protected onCreateApi<T extends CoreApi>(serverType: ServerType): T {
    if (serverType === ServerType.JELLYFIN) {
      return new JellyfinFinApi(this.context, this.clientInfo, this.deviceInfo) as ESObject as T
    }
    throw new Error(serverType + " not implemented.");
  }

}
