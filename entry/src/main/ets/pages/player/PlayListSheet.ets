import { Sheet } from "@ohpg/fin-framework";
import { ComponentContent, UIContext } from "@kit.ArkUI";
import { PlaylistPage } from "./list/PlaylistPage";
import { deviceInfo } from "@kit.BasicServicesKit";

/**
 * @Author peerless2012
 * @Email peerless2012@126.com
 * @DateTime 2024/12/7 19:43
 * @Version V1.0
 * @Description
 */
export class PlayListSheet extends Sheet {

  private callback: Callback<void> = () => {
    this.dismiss(true)
  }

  constructor(context: UIContext) {
    super(context)
    this.options.width = deviceInfo.deviceType === 'phone' ? '100%' : "60%"
  }

  protected onCreateContent(): ComponentContent<object> {
    return new ComponentContent(this.uiContext, wrapBuilder(playListComponent), this.callback)
  }

}

@Builder
function playListComponent(callback: Callback<void>) {
  PlaylistPage({ callback: callback })
}