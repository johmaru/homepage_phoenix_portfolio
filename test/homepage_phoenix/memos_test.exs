defmodule HomepagePhoenix.MemosTest do
  use HomepagePhoenix.DataCase, async: true

  alias HomepagePhoenix.AccountsFixtures
  alias HomepagePhoenix.Memos
  alias HomepagePhoenix.Memos.Memo

  describe "create_memo/2" do
    setup do
      user = AccountsFixtures.admin_user_fixture()
      scope = AccountsFixtures.user_scope_fixture(user)
      {:ok, user: user, scope: scope}
    end

    test "管理者 scope のユーザーを所有者にして UUID share_id を自動生成する", %{
      scope: scope,
      user: user
    } do
      assert {:ok, %Memo{} = memo} = Memos.create_memo(scope, valid_memo_attrs())

      assert memo.user_id == user.id
      assert memo.user.id == user.id
      assert {:ok, _uuid} = Ecto.UUID.cast(memo.share_id)
    end

    test "user_id と share_id は attrs から上書きできない", %{scope: scope, user: user} do
      other_user = AccountsFixtures.user_fixture()
      supplied_share_id = "00000000-0000-0000-0000-000000000001"

      attrs =
        valid_memo_attrs(%{
          "user_id" => other_user.id,
          "share_id" => supplied_share_id
        })

      assert {:ok, memo} = Memos.create_memo(scope, attrs)
      assert memo.user_id == user.id
      assert memo.share_id != supplied_share_id
      assert {:ok, _uuid} = Ecto.UUID.cast(memo.share_id)
    end

    test "title が空だと changeset エラーになる", %{scope: scope} do
      assert {:error, changeset} = Memos.create_memo(scope, valid_memo_attrs(%{"title" => ""}))
      assert errors_on(changeset).title
    end

    test "body が空だと changeset エラーになる", %{scope: scope} do
      assert {:error, changeset} = Memos.create_memo(scope, valid_memo_attrs(%{"body" => ""}))
      assert errors_on(changeset).body
    end

    test "visibility が不正だと changeset エラーになる", %{scope: scope} do
      attrs = valid_memo_attrs(%{"visibility" => "private"})

      assert {:error, changeset} = Memos.create_memo(scope, attrs)
      assert errors_on(changeset).visibility
    end
  end

  describe "公開クエリ" do
    setup do
      user = AccountsFixtures.admin_user_fixture()
      scope = AccountsFixtures.user_scope_fixture(user)
      {:ok, scope: scope}
    end

    test "公開一覧と sitemap は public のみ返し、share_id 取得は unlisted も返す", %{scope: scope} do
      public = create_memo(scope, %{"title" => "公開メモ", "visibility" => "public"})
      unlisted = create_memo(scope, %{"title" => "限定メモ", "visibility" => "unlisted"})

      public_memos = Memos.list_public_memos()
      public_ids = Enum.map(public_memos, & &1.id)

      assert public.id in public_ids
      refute unlisted.id in public_ids
      assert Enum.all?(public_memos, &(&1.visibility == "public"))

      sitemap_share_ids =
        Memos.list_public_memos_for_sitemap()
        |> Enum.map(& &1.share_id)

      assert public.share_id in sitemap_share_ids
      refute unlisted.share_id in sitemap_share_ids

      assert %Memo{id: unlisted_id, visibility: "unlisted"} =
               Memos.get_memo_by_share_id!(unlisted.share_id)

      assert unlisted_id == unlisted.id
    end

    test "不正な share_id は存在しないメモとして扱う" do
      assert_raise Ecto.NoResultsError, fn ->
        Memos.get_memo_by_share_id!("not-a-uuid")
      end
    end
  end

  describe "管理側" do
    setup do
      user = AccountsFixtures.admin_user_fixture()
      scope = AccountsFixtures.user_scope_fixture(user)
      {:ok, scope: scope}
    end

    test "visibility を更新できる", %{scope: scope} do
      memo = create_memo(scope, %{"visibility" => "unlisted"})

      assert {:ok, updated} = Memos.update_memo(memo, %{"visibility" => "public"})
      assert updated.visibility == "public"
      assert Memos.get_memo_by_share_id!(memo.share_id).visibility == "public"
    end

    test "delete_memo で削除すると share_id から取得できなくなる", %{scope: scope} do
      memo = create_memo(scope)

      assert {:ok, _deleted_memo} = Memos.delete_memo(memo)

      assert_raise Ecto.NoResultsError, fn ->
        Memos.get_memo_by_share_id!(memo.share_id)
      end
    end
  end

  defp valid_memo_attrs(overrides \\ %{}) do
    %{
      "title" => "テストメモ",
      "body" => "メモ本文です",
      "visibility" => "public"
    }
    |> Map.merge(overrides)
  end

  defp create_memo(scope, overrides \\ %{}) do
    {:ok, memo} = Memos.create_memo(scope, valid_memo_attrs(overrides))
    memo
  end
end
