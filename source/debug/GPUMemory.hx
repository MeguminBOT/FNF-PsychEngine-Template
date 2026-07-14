package debug;

/**
 * Best-effort dedicated VRAM usage reader for the FPS counter.
 *
 * Uses DXGI (`IDXGIAdapter3::QueryVideoMemoryInfo`) on Windows to report the
 * driver's reported *local* (dedicated) video memory currently in use by this
 * process's adapter, in bytes. Returns 0 when unavailable (non-Windows, no
 * HARDWARE_ALLOWED, old driver, or any failure).
 *
 * NOTE: this is native inline C++; it is only verified to Haxe-typecheck here.
 * A real native build is required to confirm it links (needs dxgi.lib, added
 * via the @:buildXml below). If a build ever fails on this file, deleting it +
 * the fpsShowGPUMem usage is a clean removal.
 */
#if (HARDWARE_ALLOWED && cpp && windows)
@:buildXml('<target id="haxe"><section if="windows"><lib name="dxgi.lib" /></section></target>')
@:cppFileCode('#include <dxgi1_4.h>')
#end
class GPUMemory {
	/**
	 * Current dedicated VRAM usage of the primary adapter, in bytes (0 if N/A).
	 */
	public static function getUsedBytes():Float {
		#if (HARDWARE_ALLOWED && cpp && windows)
		var result:Float = 0;
		untyped __cpp__('
			IDXGIFactory4* factory = nullptr;
			if (SUCCEEDED(CreateDXGIFactory1(__uuidof(IDXGIFactory4), (void**)&factory))) {
				IDXGIAdapter1* adapter1 = nullptr;
				if (factory->EnumAdapters1(0, &adapter1) != DXGI_ERROR_NOT_FOUND) {
					IDXGIAdapter3* adapter3 = nullptr;
					if (SUCCEEDED(adapter1->QueryInterface(__uuidof(IDXGIAdapter3), (void**)&adapter3))) {
						DXGI_QUERY_VIDEO_MEMORY_INFO vmInfo;
						if (SUCCEEDED(adapter3->QueryVideoMemoryInfo(0, DXGI_MEMORY_SEGMENT_GROUP_LOCAL, &vmInfo))) {
							{0} = (double)vmInfo.CurrentUsage;
						}
						adapter3->Release();
					}
					adapter1->Release();
				}
				factory->Release();
			}
		', result);
		return result;
		#else
		return 0;
		#end
	}
}
