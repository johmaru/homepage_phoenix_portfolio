defmodule HomepagePhoenixWeb.ProfileLive do
  use HomepagePhoenixWeb, :live_view

  defp ranking_item_classes(first?, flavor) do
    first_color =
      case flavor do
        :primary -> "border-primary/30 bg-primary/5"
        :secondary -> "border-secondary/30 bg-secondary/5"
        :accent -> "border-accent/30 bg-accent/5"
      end

    badge_color =
      case flavor do
        :primary -> "bg-primary text-primary-content"
        :secondary -> "bg-secondary text-secondary-content"
        :accent -> "bg-accent text-accent-content"
      end

    {
      [
        "flex items-center gap-3 rounded-lg border px-4 py-3",
        if(first?, do: first_color, else: "border-base-300 bg-base-200/30")
      ],
      [
        "flex size-8 shrink-0 items-center justify-center rounded-full text-sm font-bold",
        if(first?, do: badge_color, else: "bg-base-300 text-base-content")
      ]
    }
  end

  attr :items, :list, required: true
  attr :flavor, :atom, required: true

  defp ranking_list(assigns) do
    ~H"""
    <ol class="mt-4 space-y-2">
      <%= for {item, idx} <- Enum.with_index(@items) do %>
        <% rank = idx + 1 %>
        <% first? = idx == 0 %>
        <% {item_cls, badge_cls} = ranking_item_classes(first?, @flavor) %>
        <li class={item_cls}>
          <span class={badge_cls}>
            {rank}
          </span>
          <div class="group/thumb relative size-12 shrink-0 overflow-hidden rounded-md border border-base-300 bg-base-300">
            <%= if item[:image] do %>
              <img
                src={item.image}
                alt={item.title}
                loading="lazy"
                class="size-full object-cover"
              />
            <% end %>
            <span class="absolute inset-0 flex items-center justify-center text-xs font-bold text-base-content/60 group-has-[img]/thumb:hidden">
              {String.slice(item.title, 0, 2)}
            </span>
          </div>
          <div class="min-w-0 flex-1">
            <p class="truncate text-sm text-base-content">{item.title}</p>

            <.link
              href={item.url}
              target="_blank"
              class="truncate block text-xs text-base-content/50 hover:underline"
            >
              {item.url}
            </.link>
          </div>
        </li>
      <% end %>
    </ol>
    """
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <section class="hero relative overflow-hidden">
        <div
          id="aurora-bg"
          class="aurora-bg"
          aria-hidden="true"
          phx-hook="AuroraCursor"
          phx-update="ignore"
        >
          <div class="aurora-blob aurora-blob-1"></div>

          <div class="aurora-blob aurora-blob-2"></div>

          <div class="aurora-blob aurora-blob-3"></div>

          <div class="aurora-blob aurora-blob-4"></div>

          <div class="aurora-blob aurora-blob-5"></div>

          <div class="aurora-blob aurora-blob-6"></div>

          <div class="aurora-blob aurora-blob-7"></div>

          <div class="aurora-blob aurora-blob-8"></div>

          <div class="aurora-blob aurora-blob-9"></div>

          <div class="aurora-blob aurora-blob-10"></div>

          <div class="aurora-cursor-glow" id="aurora-cursor-glow"></div>
        </div>

        <div class="relative z-10 flex min-h-[40vh] items-center justify-center px-4 py-16">
          <div class="text-center">
            <h1 class="text-2xl font-bold tracking-tight sm:text-3xl">Johmaru</h1>

            <p class="mt-2 text-sm text-base-content/70">Profile</p>
          </div>
        </div>
      </section>

      <section class="mx-auto max-w-4xl px-4 py-12 sm:px-6 lg:px-8">
        <h2 class="border-b border-base-300 pb-2 text-xl font-semibold">About Me</h2>

        <p class="mt-4 text-base-content/80 leading-relaxed">色々なことをやっています。</p>
        <p class="mt-4 text-base-content/80 leading-relaxed">興味があることをその時にやっています。</p>
        <p class="mt-4 text-base-content/80 leading-relaxed">普段は大体TwitterかDiscordに生息しています。</p>
      </section>

      <section class="mx-auto max-w-4xl px-4 py-12 sm:px-6 lg:px-8">
        <h2 class="border-b border-base-300 pb-2 text-xl font-semibold">Skills</h2>

        <div class="mt-4 flex flex-wrap gap-2">
          <%= for skill <- @skills do %>
            <span class="flex items-center gap-2 rounded-lg border border-base-300 bg-base-200/50 px-3 py-1.5 text-sm">
              <img
                src={skill.icon}
                alt=""
                class={["size-4", skill[:invert] && "invert"]}
              />
              {skill.name}
            </span>
          <% end %>
        </div>
      </section>

      <section class="mx-auto max-w-4xl px-4 py-12 sm:px-6 lg:px-8">
        <h2 class="border-b border-base-300 pb-2 text-xl font-semibold">Hobbies</h2>

        <p class="mt-4 text-base-content/80 leading-relaxed">プログラミング、ラテン語、音楽視聴</p>
      </section>

      <section class="mx-auto max-w-4xl px-4 py-12 sm:px-6 lg:px-8">
        <h2 class="border-b border-base-300 pb-2 text-xl font-semibold">好きなゲーム Top 5</h2>
        <.ranking_list items={@top_games} flavor={:primary} />
      </section>

      <section class="mx-auto max-w-4xl px-4 py-12 sm:px-6 lg:px-8">
        <h2 class="border-b border-base-300 pb-2 text-xl font-semibold">好きなソシャゲ Top 5</h2>
        <.ranking_list items={@top_social_games} flavor={:secondary} />
      </section>

      <section class="mx-auto max-w-4xl px-4 py-12 sm:px-6 lg:px-8">
        <h2 class="border-b border-base-300 pb-2 text-xl font-semibold">好きなアニメ Top 5</h2>
        <.ranking_list items={@top_anime} flavor={:accent} />
      </section>

      <section class="mx-auto max-w-4xl px-4 py-12 sm:px-6 lg:px-8">
        <h2 class="border-b border-base-300 pb-2 text-xl font-semibold">Links</h2>

        <div class="mt-4 flex flex-wrap gap-3">
          <.link
            href="https://github.com/johmaru"
            target="_blank"
            class="flex items-center gap-2 rounded-lg border border-base-300 bg-base-200/50 px-4 py-2 text-sm transition-colors hover:bg-base-200"
          >
            <svg class="size-4" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
              <path d="M12 .297c-6.63 0-12 5.373-12 12 0 5.303 3.438 9.8 8.205 11.385.6.113.82-.258.82-.577 0-.285-.01-1.04-.015-2.04-3.338.724-4.042-1.61-4.042-1.61C4.422 18.07 3.633 17.7 3.633 17.7c-1.087-.744.084-.729.084-.729 1.205.084 1.838 1.236 1.838 1.236 1.07 1.835 2.809 1.305 3.495.998.108-.776.417-1.305.76-1.605-2.665-.3-5.466-1.332-5.466-5.93 0-1.31.465-2.38 1.235-3.22-.135-.303-.54-1.523.105-3.176 0 0 1.005-.322 3.3 1.23.96-.267 1.98-.399 3-.405 1.02.006 2.04.138 3 .405 2.28-1.552 3.285-1.23 3.285-1.23.645 1.653.24 2.873.12 3.176.765.84 1.23 1.91 1.23 3.22 0 4.61-2.805 5.625-5.475 5.92.42.36.81 1.096.81 2.22 0 1.606-.015 2.896-.015 3.286 0 .315.21.69.825.57C20.565 22.092 24 17.592 24 12.297c0-6.627-5.373-12-12-12" />
            </svg>
            GitHub
          </.link>
          <.link
            href="https://x.com/Johmaru_gamer"
            target="_blank"
            class="flex items-center gap-2 rounded-lg border border-base-300 bg-base-200/50 px-4 py-2 text-sm transition-colors hover:bg-base-200"
          >
            <svg class="size-4" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
              <path d="M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-5.214-6.817L4.99 21.75H1.68l7.73-8.835L1.254 2.25H8.08l4.713 6.231zm-1.161 17.52h1.833L7.084 4.126H5.117z" />
            </svg>
            X (Twitter)
          </.link>
        </div>
      </section>

      <footer class="mx-auto max-w-4xl px-4 pb-12 sm:px-6 lg:px-8">
        <p class="border-t border-base-300 pt-6 text-xs leading-relaxed text-base-content/40">
          本ページに掲載しているロゴ・画像は、作品紹介を目的とした非営利の個人サイトとして掲載しており、権利を侵害する意図はありません。各ロゴ・画像の著作権その他の権利は、それぞれの権利者に帰属します。掲載に問題がある場合はご連絡いただければ速やかに対応いたします。
        </p>
      </footer>
    </Layouts.app>
    """
  end

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:skills, [
       %{name: "C#", icon: "/images/langs/csharp.svg"},
       %{name: "C/C++", icon: "/images/langs/cpp.svg"},
       %{name: "Zig", icon: "/images/langs/zig.svg"},
       %{name: "Rust", icon: "/images/langs/rust.svg", invert: true},
       %{name: "Go", icon: "/images/langs/go.svg"},
       %{name: "Python", icon: "/images/langs/python.svg"},
       %{name: "Elixir", icon: "/images/langs/elixir.png"}
     ])
     |> assign(:top_games, [
       %{
         title: "LOL",
         url: "https://www.leagueoflegends.com/ja-jp/",
         image: "/images/rankings/lol.svg"
       },
       %{
         title: "SF2",
         url:
           "https://ja.wikipedia.org/wiki/%E3%82%B9%E3%83%9A%E3%82%B7%E3%83%A3%E3%83%AB%E3%83%95%E3%82%A9%E3%83%BC%E3%82%B92",
         image: "/images/rankings/sf2.png"
       },
       %{
         title: "Minecraft",
         url: "https://www.minecraft.net/ja-jp",
         image: "/images/rankings/minecraft.jpg"
       },
       %{
         title: "R6S",
         url: "https://www.ubisoft.com/ja-jp/game/rainbow-six/siege",
         image: "/images/rankings/r6s.jpg"
       },
       %{
         title: "BDO",
         url: "https://www.jp.playblackdesert.com/ja-JP/Main/Index",
         image: "/images/rankings/bdo.jpg"
       }
     ])
     |> assign(:top_social_games, [
       %{title: "アイプラ", url: "https://idolypride.jp/", image: "/images/rankings/aipla.png"},
       %{title: "NIKKE", url: "https://nikke-jp.com/", image: "/images/rankings/nikke.jpg"},
       %{
         title: "プリコネ",
         url: "https://priconne-redive.jp/",
         image: "/images/rankings/purikone.jpg"
       },
       %{
         title: "ユメステ",
         url: "https://wds-stellarium.com/game",
         image: "/images/rankings/yumeste.jpg"
       },
       %{
         title: "シャニマス",
         url: "https://shinycolors.idolmaster.jp/",
         image: "/images/rankings/shanimas.png"
       }
     ])
     |> assign(:top_anime, [
       %{title: "タイトル1", url: "https://example.com/anime1"},
       %{title: "タイトル2", url: "https://example.com/anime2"},
       %{title: "タイトル3", url: "https://example.com/anime3"},
       %{title: "タイトル4", url: "https://example.com/anime4"},
       %{title: "タイトル5", url: "https://example.com/anime5"}
     ])
     |> assign(:page_title, "プロフィール")
     |> assign(:meta_description, "Johmaruのプロフィール")
     |> assign(:canonical_url, HomepagePhoenix.Blog.Seo.absolute_url("/profile"))
     |> assign(:og_type, "website")
     |> assign(:og_image, nil)
     |> assign(:json_ld, nil)}
  end
end
