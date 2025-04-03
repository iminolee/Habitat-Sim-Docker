# test_sim_sensor.py
import os
import habitat_sim
from habitat_sim.utils.common import quat_from_angle_axis
from magnum import Quaternion, Vector3, Rad
import numpy as np
import matplotlib.pyplot as plt

# Default simulator settings
settings = {
    "scene": "data/scene_datasets/test_scene/HM3D/00802-wcojb4TFT35/wcojb4TFT35.basis.glb",
    "scene_config": "data/scene_datasets/test_scene/HM3D/hm3d_annotated_basis.scene_dataset_config.json",
    "sensor_height": 1.5,
    "width": 256,
    "height": 256,
    "output_dir": "data/scene_datasets/test_scene/sensor_outputs",
}

os.makedirs(settings["output_dir"], exist_ok=True)

def create_simulator(settings):
    sim_cfg = habitat_sim.SimulatorConfiguration()
    sim_cfg.scene_id = settings["scene"]
    sim_cfg.scene_dataset_config_file = settings["scene_config"]

    sensor_specs = []
    for sensor_type, uuid in [
        (habitat_sim.SensorType.COLOR, "color_sensor"),
        (habitat_sim.SensorType.DEPTH, "depth_sensor"),
        (habitat_sim.SensorType.SEMANTIC, "semantic_sensor"),
    ]:
        spec = habitat_sim.CameraSensorSpec()
        spec.uuid = uuid
        spec.sensor_type = sensor_type
        spec.resolution = [settings["height"], settings["width"]]
        spec.position = [0.0, settings["sensor_height"], 0.0]
        sensor_specs.append(spec)

    agent_cfg = habitat_sim.agent.AgentConfiguration(sensor_specifications=sensor_specs)
    cfg = habitat_sim.Configuration(sim_cfg, [agent_cfg])

    return habitat_sim.Simulator(cfg)

def visualize_semantics(semantic_img):
    unique_ids = np.unique(semantic_img)
    semantic_vis = np.zeros((*semantic_img.shape, 3), dtype=np.uint8)
    np.random.seed(0)
    for uid in unique_ids:
        if uid == 0:
            continue
        color = np.random.randint(0, 255, 3)
        semantic_vis[semantic_img == uid] = color
    return semantic_vis

def save_observation(rgb, depth, semantic, output_dir, idx):
    fig, axes = plt.subplots(1, 3, figsize=(12, 4))
    labels = ["RGB", "Depth", "Semantic"]
    images = [rgb, depth, semantic]

    for ax, img, title in zip(axes, images, labels):
        ax.set_title(title)
        ax.axis("off")
        ax.imshow(img, cmap="gray" if title == "Depth" else None)

    plt.tight_layout()
    save_path = os.path.join(output_dir, f"observation_{idx}.png")
    plt.savefig(save_path)
    plt.close()

def main():
    sim = create_simulator(settings)

    try:
        for i in range(1, 6):
            position = sim.pathfinder.get_random_navigable_point()
            yaw_rad = np.deg2rad(np.random.uniform(0, 360))

            agent = sim.agents[0]
            agent.scene_node.rotation = Quaternion()
            agent.scene_node.translation = position
            agent.scene_node.rotate_y(Rad(yaw_rad))

            obs = sim.get_sensor_observations()
            rgb = obs["color_sensor"][:, :, :3]

            depth = obs["depth_sensor"]
            depth = np.clip(depth, 0, 10)
            depth /= (depth.max() + 1e-6)

            semantic = visualize_semantics(obs["semantic_sensor"])

            save_observation(rgb, depth, semantic, settings["output_dir"], i)

        print(f"[✓] All observations saved successfully!")
        
    finally:
        sim.close()

if __name__ == "__main__":
    main()