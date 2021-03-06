class Kaui::BundleTagsController < Kaui::EngineController

  def show
    bundle_id = params[:id]
    if bundle_id.present?
      begin
        tags = Kaui::KillbillHelper::get_tags_for_bundle(bundle_id)
      rescue => e
        flash[:error] = "Error while retrieving tags information: #{as_string(e)}"
      end
    else
      flash[:error] = "No account id given"
    end
  end

  def edit
    @bundle_id = params[:bundle_id]
    begin
      @available_tags = Kaui::KillbillHelper::get_tag_definitions.sort {|tag_a, tag_b| tag_a.name.downcase <=> tag_b.name.downcase }

      @bundle = Kaui::KillbillHelper::get_bundle(@bundle_id)
      @tags = Kaui::KillbillHelper::get_tags_for_bundle(@bundle_id)
    rescue => e
      flash[:error] = "Error while retrieving tags information: #{as_string(e)}"
    end
  end

  def update
    begin
      bundle = Kaui::KillbillHelper::get_bundle(params[:bundle_id])
      tags = params[:tags]

      Kaui::KillbillHelper::set_tags_for_bundle(bundle.bundle_id, tags)
      redirect_to Kaui.bundle_home_path.call(bundle.bundle_id)
    rescue => e
      flash[:error] = "Error while updating tags: #{as_string(e)}"
    end
  end

end
