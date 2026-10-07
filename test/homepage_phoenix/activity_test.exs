defmodule HomepagePhoenix.ActivityTest do
  use HomepagePhoenix.DataCase, async: true

  alias HomepagePhoenix.Activity
  alias HomepagePhoenix.Activity.Entry
  alias HomepagePhoenix.AccountsFixtures

  describe "create_entry/2" do
    setup do
      user = AccountsFixtures.user_fixture()
      scope = AccountsFixtures.user_scope_fixture(user)
      {:ok, user: user, scope: scope}
    end

    test "正常系: activity エントリを作成できる", %{scope: scope} do
      attrs = valid_entry_attrs(%{"kind" => "activity"})

      assert {:ok, %Entry{} = entry} = Activity.create_entry(scope, attrs)
      assert entry.kind == "activity"
      assert entry.title == attrs["title"]
      assert entry.body == attrs["body"]
      assert entry.status == attrs["status"]
      assert entry.occurred_at
      assert entry.user_id == scope.user.id
    end

    test "正常系: update エントリを作成できる", %{scope: scope} do
      attrs = valid_entry_attrs(%{"kind" => "update"})

      assert {:ok, %Entry{} = entry} = Activity.create_entry(scope, attrs)
      assert entry.kind == "update"
    end

    test "異常系: title が空だとエラー", %{scope: scope} do
      attrs = valid_entry_attrs(%{"title" => ""})

      assert {:error, changeset} = Activity.create_entry(scope, attrs)
      assert changeset.errors[:title]
    end

    test "異常系: body が空だとエラー", %{scope: scope} do
      attrs = valid_entry_attrs(%{"body" => ""})

      assert {:error, changeset} = Activity.create_entry(scope, attrs)
      assert changeset.errors[:body]
    end

    test "異常系: kind が不正だとエラー", %{scope: scope} do
      attrs = valid_entry_attrs(%{"kind" => "event"})

      assert {:error, changeset} = Activity.create_entry(scope, attrs)
      assert changeset.errors[:kind]
    end

    test "異常系: published で occurred_at がないとエラー", %{scope: scope} do
      attrs = valid_entry_attrs(%{"status" => "published", "occurred_at" => nil})

      assert {:error, changeset} = Activity.create_entry(scope, attrs)
      assert changeset.errors[:occurred_at]
    end

    test "user_id は attrs から上書きできない", %{scope: scope} do
      other_user = AccountsFixtures.user_fixture()

      attrs = valid_entry_attrs(%{"user_id" => other_user.id})

      assert {:ok, entry} = Activity.create_entry(scope, attrs)
      assert entry.user_id == scope.user.id
    end
  end

  describe "公開クエリ" do
    setup do
      user = AccountsFixtures.user_fixture()
      scope = AccountsFixtures.user_scope_fixture(user)
      {:ok, scope: scope}
    end

    test "list_entries は published のみ返す", %{scope: scope} do
      published = create_published_entry(scope, %{"title" => "公開エントリ"})
      create_draft_entry(scope, %{"title" => "下書きエントリ"})

      result = Activity.list_entries()

      assert Enum.map(result.entries, & &1.id) |> Enum.member?(published.id)
      refute Enum.any?(result.entries, &(&1.title == "下書きエントリ"))
    end

    test "list_entries は未来の occurred_at を除外する", %{scope: scope} do
      create_entry(scope, %{
        "title" => "未来エントリ",
        "status" => "published",
        "occurred_at" => future_iso()
      })

      assert Activity.list_entries().entries == []
    end

    test "list_entries は kind で絞り込める", %{scope: scope} do
      activity = create_published_entry(scope, %{"kind" => "activity", "title" => "活動A"})
      update = create_published_entry(scope, %{"kind" => "update", "title" => "更新B"})

      assert [%Entry{id: id}] = Activity.list_entries(kind: "update").entries
      assert id == update.id

      assert [%Entry{id: id}] = Activity.list_entries(kind: "activity").entries
      assert id == activity.id
    end

    test "list_recent_entries は published のみ limit 件返す", %{scope: scope} do
      entries = for i <- 1..3, do: create_published_entry(scope, %{"title" => "公開#{i}"})
      create_draft_entry(scope, %{"title" => "下書き"})

      result = Activity.list_recent_entries(limit: 2)

      assert length(result) == 2
      # occurred_at 同時なら id 降順（新しい順）
      assert Enum.map(result, & &1.id) ==
               entries |> Enum.reverse() |> Enum.take(2) |> Enum.map(& &1.id)
    end

    test "list_recent_entries は未来の occurred_at を除外する", %{scope: scope} do
      create_entry(scope, %{
        "title" => "未来エントリ",
        "status" => "published",
        "occurred_at" => future_iso()
      })

      assert Activity.list_recent_entries() == []
    end
  end

  describe "管理側" do
    setup do
      user = AccountsFixtures.user_fixture()
      scope = AccountsFixtures.user_scope_fixture(user)
      {:ok, user: user, scope: scope}
    end

    test "list_admin_entries は draft 含む全件を返す", %{scope: scope} do
      published = create_published_entry(scope)
      draft = create_draft_entry(scope)

      ids = Activity.list_admin_entries() |> Enum.map(& &1.id)

      assert published.id in ids
      assert draft.id in ids
    end

    test "get_admin_entry! で id 取得できる", %{scope: scope} do
      entry = create_published_entry(scope)

      assert Activity.get_admin_entry!(entry.id).id == entry.id
    end

    test "update_entry で更新できる", %{scope: scope} do
      entry = create_draft_entry(scope)

      assert {:ok, entry} = Activity.update_entry(entry, %{"title" => "更新後タイトル"})
      assert entry.title == "更新後タイトル"
    end

    test "publish_entry は occurred_at を補完して公開する", %{scope: scope} do
      entry = create_draft_entry(scope)

      assert {:ok, entry} = Activity.publish_entry(entry)
      assert entry.status == "published"
      assert entry.occurred_at
    end

    test "delete_entry で削除できる", %{scope: scope} do
      entry = create_published_entry(scope)

      assert {:ok, _} = Activity.delete_entry(entry)

      assert_raise Ecto.NoResultsError, fn ->
        Activity.get_admin_entry!(entry.id)
      end
    end
  end

  # ヘルパー

  defp valid_entry_attrs(overrides) do
    %{
      "kind" => "activity",
      "title" => "テスト活動",
      "body" => "短い説明",
      "status" => "published",
      "occurred_at" => DateTime.utc_now() |> DateTime.to_iso8601()
    }
    |> Map.merge(overrides)
  end

  defp create_published_entry(scope, overrides \\ %{}) do
    attrs =
      valid_entry_attrs(overrides)
      |> Map.put("status", "published")
      |> Map.put("occurred_at", DateTime.utc_now() |> DateTime.to_iso8601())

    {:ok, entry} = Activity.create_entry(scope, attrs)
    entry
  end

  defp create_draft_entry(scope, overrides \\ %{}) do
    attrs =
      valid_entry_attrs(overrides)
      |> Map.put("status", "draft")
      |> Map.delete("occurred_at")

    {:ok, entry} = Activity.create_entry(scope, attrs)
    entry
  end

  defp create_entry(scope, overrides) do
    {:ok, entry} = Activity.create_entry(scope, valid_entry_attrs(overrides))
    entry
  end

  defp future_iso do
    DateTime.utc_now() |> DateTime.add(3600, :second) |> DateTime.to_iso8601()
  end
end
